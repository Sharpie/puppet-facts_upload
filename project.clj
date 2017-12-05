(def puppetserver-version
  "Version of Puppet Server to develop and test against"
  "5.1.4")

(defproject sharpie/facts-upload "1.0.0"
  :description "Puppet Server endpoint for the facts upload command"
  :license {:name "Apache License 2.0"
            :url "http://www.apache.org/licenses/LICENSE-2.0.html"}

  :pedantic? :abort

  :min-lein-version "2.7.1"

  :plugins [[lein-parent "0.3.1"]]

  :parent-project {:coords [puppetlabs/clj-parent "1.4.3"]
                   :inherit [:managed-dependencies]}

  :source-paths ["src/clj"]
  :resource-paths ["src/ruby"]
  :test-paths ["test/integration"]

  :dependencies [[org.clojure/clojure]

                 [ring/ring-core]

                 [puppetlabs/comidi]
                 [puppetlabs/ring-middleware]

                 [puppetlabs/trapperkeeper]
                 [puppetlabs/trapperkeeper-status]
                 [puppetlabs/trapperkeeper-webserver-jetty9]

                 [puppetlabs/puppetserver ~puppetserver-version]]

  :profiles {:dev {:source-paths ["dev"]
                   :repl-options {:init-ns tk-devtools}
                   :resource-paths ["dev-resources"]
                   :dependencies [[org.clojure/tools.namespace]
                                  [org.clojure/tools.nrepl]

                                  [cheshire]
                                  [ring-mock]

                                  ;; Re-declare dependencies with "test"
                                  ;; classifiers to pull in additional testing
                                  ;; code, helper functions and libraries.
                                  [puppetlabs/trapperkeeper-webserver-jetty9 nil :classifier "test"]
                                  [puppetlabs/trapperkeeper nil :classifier "test" :scope "test"]
                                  [puppetlabs/kitchensink nil :classifier "test" :scope "test"]

                                  [puppetlabs/http-client]
                                  [me.raynes/fs]
                                  ;; Convert data between JRuby and Clojure objects.
                                  [zweikopf "1.0.2" :exclusions [org.jruby/jruby-complete]]

                                  [puppetlabs/puppetserver ~puppetserver-version :classifier "test" :scope "test"]]}

             :puppet-module {:jar-name "facts-upload.jar"}}

  :test-selectors {:integration :integration}

  :aliases {"tk" ["trampoline" "run"
                  "--bootstrap-config" "dev-resources/facts-upload/bootstrap.cfg"
                  "--config" "dev-resources/facts-upload/config.conf"]}

  :main puppetlabs.trapperkeeper.main)
