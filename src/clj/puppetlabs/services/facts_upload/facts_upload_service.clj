(ns puppetlabs.services.facts-upload.facts-upload-service
  (:require
   [clojure.tools.logging :as log]
   [puppetlabs.services.facts-upload.facts-upload-core :as core]
   [puppetlabs.trapperkeeper.core :refer [defservice]]
   [puppetlabs.trapperkeeper.services :as services]
   [puppetlabs.trapperkeeper.services.status.status-core :as status-core]))


(defprotocol FactsUploadService)

(defservice facts-upload-service
  FactsUploadService
  [[:StatusService register-status]]
  (init [this context]
    (log/info "Initializing FileServing service")
    (register-status "facts-upload"
                     (status-core/get-artifact-version "sharpie" "facts-upload")
                     1
                     (core/create-status-callback context))

    context)

  (start [this context]
    (log/info "Starting FactsUploadService")
    context)

  (stop [this context]
    (log/info "Shutting down FactsUploadService")
    context))
