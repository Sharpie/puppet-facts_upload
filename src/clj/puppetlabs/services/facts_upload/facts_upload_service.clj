(ns puppetlabs.services.facts-upload.facts-upload-service
  (:require
   [clojure.tools.logging :as log]
   [puppetlabs.services.facts-upload.facts-upload-core :as core]
   [puppetlabs.trapperkeeper.core :refer [defservice]]
   [puppetlabs.trapperkeeper.services :as services]
   [puppetlabs.trapperkeeper.services.status.status-core :as status-core]))


(def version
  "The service version, from project.clj"
  (status-core/get-artifact-version "sharpie" "facts-upload"))

(defprotocol FactsUploadService)

(defservice facts-upload-service
  FactsUploadService
  [[:StatusService register-status]
   [:WebserverService add-ring-handler]

   [:PuppetServerConfigService get-config]
   [:CaService get-auth-handler]
   [:VersionedCodeService current-code-id]
   ;; Mainly here to ensure we start after the MasterService
   [:MasterService]]
  (init [this context]
    ;; TODO: Only build the handler if we detect a compatible version of
    ;; Puppet Server.
    (log/info "Initializing FileServing service")
    (let [puppet-config (get-config)
          auth-handler (get-auth-handler)
          jruby-service (services/get-service this :JRubyPuppetService)
          jruby-handler (core/create-wrapped-jruby-handler puppet-config
                                                           current-code-id
                                                           jruby-service
                                                           auth-handler)
          facts-handler (core/create-request-handler jruby-handler)]

      (register-status "facts-upload-service" version 1
                       (core/create-status-callback context))

      (assoc context :request-handler facts-handler)))


  (start [this context]
    ;; FIXME: Use the WebroutingService to lookup which path the MasterService
    ;; is mounted at.
    (when-let [handler (:request-handler context)]
      (log/info "Starting FactsUploadService")
      (add-ring-handler handler "/puppet/v3/facts"))

    context))
