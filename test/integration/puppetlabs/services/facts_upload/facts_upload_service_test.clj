(ns puppetlabs.services.facts-upload.facts-upload-service-test
  (:require
    [clojure.test :refer :all]
    [clojure.java.io :as io]

    [puppetlabs.http.client.sync :as http-client]

    [puppetlabs.trapperkeeper.app :as tk-app]
    [puppetlabs.trapperkeeper.bootstrap :as tk-bootstrap]
    [puppetlabs.trapperkeeper.config :as tk-config]
    [puppetlabs.trapperkeeper.testutils.bootstrap :as tst-bootstrap]

    ;; Provided by puppetlabs/puppetserver with the "test" classifier.
    [puppetlabs.services.jruby.jruby-puppet-testutils :as jruby-testutils]))


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
      (assoc-in [:jruby-puppet :max-active-instances] 2)))


;; Helper Functions

(defn PUT
  [path body]
  (http-client/put (str base-url path)
                    {:headers {"Accept" "application/json"
                               "Content-type" "application/json"}
                     :ssl-ca-cert ca-cert
                     :body body
                     :as :text}))


(deftest ^:integration facts-upload-endpoint
  (tst-bootstrap/with-app-with-config app app-services base-config
    (let [jruby-service (tk-app/get-service app :JRubyPuppetService)
          jruby-instance (jruby-testutils/borrow-instance jruby-service :facts-upload-endpoint-test)
          container (:scripting-container jruby-instance)]
      (try
        (let [facts (.runScriptlet container "Puppet::Node::Facts.new('test.certname').to_json")
              response (PUT "/puppet/v3/facts/test.certname?environment=production"
                            facts)]
          (testing "Puppet Server responds to PUT requests for /puppet/v3/facts"
            (is (= 200 (:status response)))))
        (finally
          (jruby-testutils/return-instance jruby-service jruby-instance :facts-upload-endpoint-test))))))
