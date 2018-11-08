(ns puppetlabs.services.facts-upload.facts-upload-service
  (:require
   [clojure.edn :as edn]
   [clojure.string :as string]
   [clojure.tools.logging :as log]
   [puppetlabs.services.facts-upload.facts-upload-core :as core]
   [puppetlabs.trapperkeeper.core :refer [defservice]]
   [puppetlabs.trapperkeeper.services :as services]
   [puppetlabs.trapperkeeper.services.status.status-core :as status-core]))


(def version
  "The facts_upload module version, from project.clj"
  (status-core/get-artifact-version "sharpie" "facts-upload"))

(def puppetserver-version
  "Retrieve Puppet Server version in use.

  This function retrieves just the X and Y components of the version
  and casts them to a floating point number that can be compared."
  (try
    (as-> (status-core/get-artifact-version "puppetlabs" "puppetserver") x
          (string/split x #"\.")
          (take 2 x)
          (string/join "." x)
          (edn/read-string x))
    (catch Exception e
      (log/errorf "Couldn't determine Puppet Server version %s" e)
      nil)))

(defprotocol FactsUploadService)


(defn compatible-puppetserver-version?
  "Determine whether Puppet Server is compatible with facts_upload.

  This function returns a simple boolean value."
  []
  (if (nil? puppetserver-version)
    false
    (and (>= puppetserver-version 2.6)
         (< puppetserver-version 5.3))))

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
    (if (compatible-puppetserver-version?)
      (do
        (log/info "Initializing FactsUpload service")
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
      (do
        (log/warnf "The facts_upload plugin is not compatible with Puppet Server version %s and should be removed from this node. Skipping service initialization."
                    puppetserver-version)
        context)))


  (start [this context]
    ;; FIXME: Use the WebroutingService to lookup which path the MasterService
    ;; is mounted at.
    (when-let [handler (:request-handler context)]
      (log/info "Starting FactsUpload service")
      (add-ring-handler handler "/puppet/v3/facts"))

    context))
