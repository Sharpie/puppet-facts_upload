(ns puppetlabs.services.facts-upload.facts-upload-service-test
  (:require
    [clojure.test :refer :all]
    [clojure.java.io :as io]
    [clojure.walk :as walk]

    [puppetlabs.http.client.sync :as http-client]
    [cheshire.core :as json]
    [me.raynes.fs :as fs]
    ;; Zweikopf converts data between JRuby and Clojure objects.
    ;; NOTE: To cut overhead, the tests below don't initialize zweikopf
    ;; with a JRuby interpreter of it's own. This means that zweikopf/clojurize
    ;; might blow up if passed exotic Ruby data structures like Rational or
    ;; struct.
    [zweikopf.core :as zweikopf]

    [puppetlabs.trapperkeeper.app :as tk-app]
    [puppetlabs.trapperkeeper.bootstrap :as tk-bootstrap]
    [puppetlabs.trapperkeeper.config :as tk-config]
    [puppetlabs.trapperkeeper.services.status.status-core :as status-core]
    [puppetlabs.trapperkeeper.testutils.bootstrap :as tst-bootstrap]

    ;; Provided by puppetlabs/puppetserver with the "test" classifier.
    [puppetlabs.services.jruby.jruby-puppet-testutils :as jruby-testutils]
    [puppetlabs.services.facts-upload.facts-upload-service :as facts-upload]))


;; Test Configuration

(defn test-resource
  "Locates a path within the registered Java resource directories and returns
  a fully qualified path"
  [path]
  (-> path
      io/resource
      .getPath))

(def bootstrap-config (test-resource "facts-upload/bootstrap.cfg"))
(def app-config (test-resource "facts-upload/config.conf"))
(def logback-config (test-resource "facts-upload/logback-test.xml"))
(def puppet-confdir (test-resource "facts-upload/fixtures/puppet"))

(def listen-address "localhost")
(def listen-port 18140)
(def base-url (str "https://" listen-address ":" listen-port))

(def ssl-cert (test-resource "facts-upload/ssl/facts-upload.test.cert.pem"))
(def ssl-key (test-resource "facts-upload/ssl/facts-upload.test.key.pem"))
(def ca-cert (test-resource "facts-upload/ssl/ca.pem"))

(def app-services
  (tk-bootstrap/parse-bootstrap-config! bootstrap-config))

(def base-config
  "Load Puppet Server dev configuration, but turn logging down,
  shift to a different port and disable SSL client auth."
  (-> app-config

      tk-config/load-config

      (assoc-in [:global :logging-config] logback-config)

      (assoc-in [:webserver :ssl-host] listen-address)
      (assoc-in [:webserver :ssl-port] listen-port)
      (assoc-in [:webserver :ssl-cert] ssl-cert)
      (assoc-in [:webserver :ssl-key] ssl-key)
      (assoc-in [:webserver :ssl-ca-cert] ca-cert)
      (assoc-in [:webserver :client-auth] "none")

      ;; The tests borrow one instance to generate test data, so we need
      ;; a second instance free to handle HTTP requests.
      (assoc-in [:jruby-puppet :max-active-instances] 2)
      (assoc-in [:jruby-puppet :master-var-dir] (fs/tmpdir))
      (assoc-in [:jruby-puppet :master-conf-dir] puppet-confdir)))


;; Helper Functions

(def fact-content-type
  (if (< facts-upload/puppetserver-version 5.0)
    "text/pson"
    "application/json"))

(defn PUT
  [path body]
  (http-client/put (str base-url path)
                    {:headers {"Accept" fact-content-type
                               "Content-type" fact-content-type}
                     :ssl-ca-cert ca-cert
                     :body body
                     :as :text}))

(defn GET
  [path]
  (http-client/get (str base-url path)
                    {:headers {"Accept" fact-content-type}
                     :ssl-ca-cert ca-cert
                     :as :text}))


(deftest ^:integration facts-upload-service
  (printf "Testing against Puppet Server version: %s%n" facts-upload/puppetserver-version)

  (tst-bootstrap/with-app-with-config app app-services base-config
    (let [jruby-service (tk-app/get-service app :JRubyPuppetService)
          jruby-instance (jruby-testutils/borrow-instance jruby-service :facts-upload-endpoint-test)
          container (:scripting-container jruby-instance)]
      (try
        (let [facts (.runScriptlet container "facts = Puppet::Node::Facts.new('puppet.node.test')
                                              facts.values['foo'] = 'bar'
                                              facts.to_json")
              response (PUT "/puppet/v3/facts/puppet.node.test?environment=production" facts)]

          (testing "Puppet Server responds to PUT requests for /puppet/v3/facts"
            (is (= 200 (:status response))))

          (testing "Puppet Server saves facts to the configured facts terminus"
            ;; Ensure the test is configured properly
            (is (= "yaml" (.runScriptlet container "Puppet::Node::Facts.indirection.terminus_class")))
            (let [stored-facts (-> (.runScriptlet container "facts = Puppet::Node::Facts.indirection.find('puppet.node.test')
                                                             facts.nil? ? {} : facts.to_data_hash")
                                   (zweikopf/clojurize)
                                   (walk/keywordize-keys))]
              (is (= "bar" (get-in stored-facts [:values :foo]))))))
        (finally
          (jruby-testutils/return-instance jruby-service jruby-instance :facts-upload-endpoint-test)))

      (testing "facts-upload plugin is enabled appropriately"
        (let [response (GET "/status/v1/services?level=debug")
              body (-> response :body json/parse-string)
              ;; When run against an incompatible Puppet Server version, we
              ;; expect the TK status service to return a response that does
              ;; not reference the facts-upload service, i.e. nil, which
              ;; indicates the service was not mounted.
              expected-version (if (facts-upload/compatible-puppetserver-version?)
                                   facts-upload/version
                                   nil)]
          (is (= 200 (:status response)))
          (is (= expected-version (get-in body ["facts-upload-service" "service_version"]))))))))
