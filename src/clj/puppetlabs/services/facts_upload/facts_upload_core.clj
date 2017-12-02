(ns puppetlabs.services.facts-upload.facts-upload-core
  (:require
   [puppetlabs.trapperkeeper.services.status.status-core :as status-core]))


;; Admin API

(defn create-status-callback
  "Creates a callback function that the trapperkeeper-status library
  can use to report on status."
  [context]
  (fn
    [level]
      (let [level>= (partial status-core/compare-levels >= level)]
        {:state :running
         :status {}})))
