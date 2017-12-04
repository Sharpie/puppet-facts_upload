(ns puppetlabs.services.facts-upload.facts-upload-core
  (:require
   [clojure.tools.logging :as log]
   [clojure.java.io :as io]
   [puppetlabs.trapperkeeper.services.status.status-core :as status-core]
   [puppetlabs.services.master.master-core :as master-core]
   [puppetlabs.services.jruby-pool-manager.jruby-core :as jruby-core]
   [puppetlabs.services.protocols.jruby-puppet :as jruby-puppet]
   [puppetlabs.services.request-handler.request-handler-core :as jruby-handler]
   [puppetlabs.puppetserver.jruby-request :as jruby-middleware]
   [puppetlabs.comidi :as comidi]
   [ring.util.response :as response]))

(def patchfile "ruby/monkeypatches/facts_upload.rb")

(def facts-upload-monkeypatch
  "Returns the path to a monkeypatch for re-enabling the facts terminus,
  if nothing terrible has happened to Java resource paths. Otherwise,
  returns nil which causes the wrap-with-monkeypatches handler to no-op."
  (when-let [monkeypatch (io/resource patchfile)]
    monkeypatch))


(defn create-status-callback
  "Creates a callback function for the trapperkeeper-status library.
  Used to report the presence of this Puppet Server extension."
  [context]
  (fn
    [level]
      (let [level>= (partial status-core/compare-levels >= level)]
        {:state :running
         :status {}})))

(defn wrap-with-monkeypatches
  "This middleware function ensures that the JRuby handling a request
  has been monkey-patched to re-enable handling of HTTP requests for
  the facts terminus."
  [handler]
  (if facts-upload-monkeypatch
    (fn [request]
      (when-let [jruby (:jruby-container request)]
        (.runScriptlet jruby
                       (io/input-stream facts-upload-monkeypatch)
                       (.getPath facts-upload-monkeypatch)))
      (handler request))
    (do
      (log/error (str "Unable to load facts_upload patch from: " patchfile))
      handler)))

(defn wrap-with-jruby-instance
  "A re-implementation of jruby-middleware/wrap-with-jruby-instance that
  exposes the scripting container in addition to the JRubyPuppet interface."
  [handler jruby-service]
  (let [jruby-pool (jruby-puppet/get-pool-context jruby-service)]
    (fn [request]
      (let [borrow-reason {:request (dissoc request :ssl-client-cert)}]
        (jruby-core/with-jruby-instance jruby-instance jruby-pool borrow-reason
          (-> request
              (assoc :jruby-instance (:jruby-puppet jruby-instance))
              (assoc :jruby-container (:scripting-container jruby-instance))
              handler))))))

(defn create-jruby-handler
  "Basically jruby-handler/build-request-handler with an injected monkeypatch."
  [jruby-service puppet-config code-id-fn]
  (let [config (jruby-handler/config->request-handler-settings puppet-config)]
    (-> (jruby-handler/jruby-request-handler config code-id-fn)
        wrap-with-monkeypatches ; <- This is the whole reason for most of the
                                ; code in this file...
        (wrap-with-jruby-instance jruby-service) ; <- This too.
        jruby-middleware/wrap-with-error-handling)))

(defn create-wrapped-jruby-handler
  "Builds a wrapped JRuby handler similar to that provided by
  the RequestHandlerService after being wrapped with authorization
  and other middleware from the MasterService.

  The reason we duplicate it here is so that we can add middleware
  that injects monkey-patches to re-activate the Ruby bits of
  the facts terminus."
  [puppet-config code-id-fn jruby-service auth-handler]
  (let [jruby-handler (create-jruby-handler jruby-service puppet-config code-id-fn)
        puppet-version (get-in puppet-config [:puppetserver :puppet-version])
        use-legacy-auth? (get-in puppet-config
                           [:jruby-puppet :use-legacy-auth-conf] false)]
    (master-core/get-wrapped-handler jruby-handler
                                     auth-handler
                                     puppet-version
                                     use-legacy-auth?)))

(defn create-request-routes
  "Builds a Comidi routing tree that responds to PUT requests for facts."
  [jruby-handler]
  (comidi/routes
    (comidi/context "/puppet/v3"
     (comidi/routes
      (comidi/PUT ["/facts/" [#".*" :rest]] request
                  (jruby-handler request))))))

(defn create-request-handler
  "Creates a Ring handler that responds to PUT requests for facts using
  a supplied JRuby handling function."
  [handler]
  (comidi/routes->handler
    (create-request-routes handler)))
