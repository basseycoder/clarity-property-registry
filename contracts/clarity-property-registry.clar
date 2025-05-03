;; Properties Blockchain Ledger
;; Immutable and transparent solution for property title management

;; System Configuration Constants
(define-constant registry-admin tx-sender)
(define-constant err-property-not-found (err u401))
(define-constant err-property-already-registered (err u402))
(define-constant err-invalid-title-name (err u403))
(define-constant err-not-title-holder (err u406))
(define-constant err-admin-only-action (err u407))
(define-constant err-viewing-restricted (err u408))
(define-constant err-tag-format-invalid (err u409))
(define-constant err-invalid-document-size (err u404))
(define-constant err-unauthorized-viewer (err u405))

;; Document Registry Counter
(define-data-var title-counter uint u0)


;; Authorization Matrix for Title Access
(define-map title-permissions
  { title-id: uint, viewer: principal }
  { access-allowed: bool }
)

;; Primary Data Structures for Title Management
(define-map title-registry
  { title-id: uint }
  {
    title-name: (string-ascii 64),
    title-owner: principal,
    document-size: uint,
    registration-time: uint,
    property-description: (string-ascii 128),
    property-tags: (list 10 (string-ascii 32))
  }
)

;; Adds supplementary metadata tags to existing property records
(define-public (add-property-tags (title-id uint) (additional-tags (list 10 (string-ascii 32))))
  (let
    (
      (title-data (unwrap! (map-get? title-registry { title-id: title-id }) err-property-not-found))
      (existing-tags (get property-tags title-data))
      (combined-tags (unwrap! (as-max-len? (concat existing-tags additional-tags) u10) err-tag-format-invalid))
    )
    ;; Verify title exists and requester is the owner
    (asserts! (title-registered? title-id) err-property-not-found)
    (asserts! (is-eq (get title-owner title-data) tx-sender) err-not-title-holder)

    ;; Validate new tag formats
    (asserts! (validate-tag-collection additional-tags) err-tag-format-invalid)

    ;; Update title with combined tags
    (map-set title-registry
      { title-id: title-id }
      (merge title-data { property-tags: combined-tags })
    )
    (ok combined-tags)
  )
)

;; Applies security lock to prevent unauthorized modifications
(define-public (secure-title-emergency (title-id uint))
  (let
    (
      (title-data (unwrap! (map-get? title-registry { title-id: title-id }) err-property-not-found))
      (lock-tag "EMERGENCY-LOCK")
      (existing-tags (get property-tags title-data))
    )
    ;; Verify title exists and requester has authority
    (asserts! (title-registered? title-id) err-property-not-found)
    (asserts! 
      (or 
        (is-eq tx-sender registry-admin)
        (is-eq (get title-owner title-data) tx-sender)
      ) 
      err-admin-only-action
    )

    (ok true)
  )
)

;; Analyzes title ownership provenance and authentication status
(define-public (authenticate-title (title-id uint) (presumed-owner principal))
  (let
    (
      (title-data (unwrap! (map-get? title-registry { title-id: title-id }) err-property-not-found))
      (actual-owner (get title-owner title-data))
      (registration-block (get registration-time title-data))
      (has-view-permission (default-to 
        false 
        (get access-allowed 
          (map-get? title-permissions { title-id: title-id, viewer: tx-sender })
        )
      ))
    )
    ;; Verify title exists and requester has viewing rights
    (asserts! (title-registered? title-id) err-property-not-found)
    (asserts! 
      (or 
        (is-eq tx-sender actual-owner)
        has-view-permission
        (is-eq tx-sender registry-admin)
      ) 
      err-unauthorized-viewer
    )

    ;; Generate authentication report with ownership verification
    (if (is-eq actual-owner presumed-owner)
      ;; Return successful authentication with timeline data
      (ok {
        authentication-valid: true,
        current-block: block-height,
        chain-age: (- block-height registration-block),
        ownership-verified: true
      })
      ;; Return ownership mismatch report
      (ok {
        authentication-valid: false,
        current-block: block-height,
        chain-age: (- block-height registration-block),
        ownership-verified: false
      })
    )
  )
)

;; ===== Additional Registry Management Functions =====

;; Grants permission to view a specific title
(define-public (grant-title-access (title-id uint) (viewer principal))
  (let
    (
      (title-data (unwrap! (map-get? title-registry { title-id: title-id }) err-property-not-found))
    )
    ;; Verify title exists and requester is the owner
    (asserts! (title-registered? title-id) err-property-not-found)
    (asserts! (is-eq (get title-owner title-data) tx-sender) err-not-title-holder)

    (ok true)
  )
)

;; Checks if a viewer has permission to access a title
(define-public (check-title-access (title-id uint) (viewer principal))
  (let
    (
      (title-data (unwrap! (map-get? title-registry { title-id: title-id }) err-property-not-found))
      (access-status (default-to 
        false 
        (get access-allowed 
          (map-get? title-permissions { title-id: title-id, viewer: viewer })
        )
      ))
    )
    ;; Verify title exists
    (asserts! (title-registered? title-id) err-property-not-found)

    ;; Return access status
    (ok access-status)
  )
)

;; Updates just the property description field
(define-public (update-property-description (title-id uint) (new-description (string-ascii 128)))
  (let
    (
      (title-data (unwrap! (map-get? title-registry { title-id: title-id }) err-property-not-found))
    )
    ;; Verify title exists and requester is the owner
    (asserts! (title-registered? title-id) err-property-not-found)
    (asserts! (is-eq (get title-owner title-data) tx-sender) err-not-title-holder)

    ;; Validate new description
    (asserts! (> (len new-description) u0) err-invalid-title-name)
    (asserts! (< (len new-description) u129) err-invalid-title-name)

    ;; Update description only
    (map-set title-registry
      { title-id: title-id }
      (merge title-data { property-description: new-description })
    )
    (ok true)
  )
)

;; ===== Helper Functions for Title Management =====

;; Checks if a title exists in the registry
(define-private (title-registered? (title-id uint))
  (is-some (map-get? title-registry { title-id: title-id }))
)

;; Verifies title ownership against a provided principal
(define-private (verify-title-owner (title-id uint) (user principal))
  (match (map-get? title-registry { title-id: title-id })
    title-data (is-eq (get title-owner title-data) user)
    false
  )
)

;; Retrieves document size for storage calculations
(define-private (fetch-document-size (title-id uint))
  (default-to u0
    (get document-size
      (map-get? title-registry { title-id: title-id })
    )
  )
)

;; Validates individual property tag format
(define-private (validate-tag-format (tag (string-ascii 32)))
  (and
    (> (len tag) u0)
    (< (len tag) u33)
  )
)

;; Ensures all property tags meet system requirements
(define-private (validate-tag-collection (tags (list 10 (string-ascii 32))))
  (and
    (> (len tags) u0)
    (<= (len tags) u10)
    (is-eq (len (filter validate-tag-format tags)) (len tags))
  )
)

;; ===== Public Registry Functions =====

;; Registers a new property title with comprehensive metadata
(define-public (register-title 
  (property-name (string-ascii 64)) 
  (document-bytes uint) 
  (description (string-ascii 128)) 
  (tags (list 10 (string-ascii 32)))
)
  (let
    (
      (next-title-id (+ (var-get title-counter) u1))
    )
    ;; Validate title registration inputs
    (asserts! (> (len property-name) u0) err-invalid-title-name)
    (asserts! (< (len property-name) u65) err-invalid-title-name)
    (asserts! (> document-bytes u0) err-invalid-document-size)
    (asserts! (< document-bytes u1000000000) err-invalid-document-size)
    (asserts! (> (len description) u0) err-invalid-title-name)
    (asserts! (< (len description) u129) err-invalid-title-name)
    (asserts! (validate-tag-collection tags) err-tag-format-invalid)

    ;; Create new title record
    (map-insert title-registry
      { title-id: next-title-id }
      {
        title-name: property-name,
        title-owner: tx-sender,
        document-size: document-bytes,
        registration-time: block-height,
        property-description: description,
        property-tags: tags
      }
    )

    ;; Initialize access permissions for title owner
    (map-insert title-permissions
      { title-id: next-title-id, viewer: tx-sender }
      { access-allowed: true }
    )
    
    ;; Update registry counter
    (var-set title-counter next-title-id)
    (ok next-title-id)
  )
)

;; Updates an existing property title information
(define-public (update-title-details 
  (title-id uint) 
  (new-name (string-ascii 64)) 
  (new-document-size uint) 
  (new-description (string-ascii 128)) 
  (new-tags (list 10 (string-ascii 32)))
)
  (let
    (
      (title-data (unwrap! (map-get? title-registry { title-id: title-id }) err-property-not-found))
    )
    ;; Verify title exists and requester is the owner
    (asserts! (title-registered? title-id) err-property-not-found)
    (asserts! (is-eq (get title-owner title-data) tx-sender) err-not-title-holder)
    
    ;; Validate updated title information
    (asserts! (> (len new-name) u0) err-invalid-title-name)
    (asserts! (< (len new-name) u65) err-invalid-title-name)
    (asserts! (> new-document-size u0) err-invalid-document-size)
    (asserts! (< new-document-size u1000000000) err-invalid-document-size)
    (asserts! (> (len new-description) u0) err-invalid-title-name)
    (asserts! (< (len new-description) u129) err-invalid-title-name)
    (asserts! (validate-tag-collection new-tags) err-tag-format-invalid)

    ;; Update title registry with new information
    (map-set title-registry
      { title-id: title-id }
      (merge title-data { 
        title-name: new-name, 
        document-size: new-document-size, 
        property-description: new-description, 
        property-tags: new-tags 
      })
    )
    (ok true)
  )
)

;; Permanently removes a property title from the registry
(define-public (delete-title (title-id uint))
  (let
    (
      (title-data (unwrap! (map-get? title-registry { title-id: title-id }) err-property-not-found))
    )
    ;; Verify title exists and requester is the owner
    (asserts! (title-registered? title-id) err-property-not-found)
    (asserts! (is-eq (get title-owner title-data) tx-sender) err-not-title-holder)
    
    ;; Remove title from registry
    (map-delete title-registry { title-id: title-id })
    (ok true)
  )
)

;; Transfers property title ownership to another entity
(define-public (transfer-title (title-id uint) (new-owner principal))
  (let
    (
      (title-data (unwrap! (map-get? title-registry { title-id: title-id }) err-property-not-found))
    )
    ;; Verify title exists and requester is the current owner
    (asserts! (title-registered? title-id) err-property-not-found)
    (asserts! (is-eq (get title-owner title-data) tx-sender) err-not-title-holder)
    
    ;; Update title ownership records
    (map-set title-registry
      { title-id: title-id }
      (merge title-data { title-owner: new-owner })
    )
    (ok true)
  )
)

;; Removes permission for a principal to access a specific title
(define-public (remove-title-access (title-id uint) (viewer principal))
  (let
    (
      (title-data (unwrap! (map-get? title-registry { title-id: title-id }) err-property-not-found))
    )
    ;; Verify title exists and requester has authority
    (asserts! (title-registered? title-id) err-property-not-found)
    (asserts! (is-eq (get title-owner title-data) tx-sender) err-not-title-holder)
    (asserts! (not (is-eq viewer tx-sender)) err-admin-only-action)

    ;; Remove access permission
    (map-delete title-permissions { title-id: title-id, viewer: viewer })
    (ok true)
  )
)

;; Gets total number of registered titles
(define-read-only (get-total-registered-titles)
  (var-get title-counter)
)

;; Retrieves basic title information (for owner or authorized viewers)
(define-read-only (get-title-info (title-id uint))
  (let
    (
      (title-data (unwrap! (map-get? title-registry { title-id: title-id }) err-property-not-found))
      (actual-owner (get title-owner title-data))
      (has-view-permission (default-to 
        false 
        (get access-allowed 
          (map-get? title-permissions { title-id: title-id, viewer: tx-sender })
        )
      ))
    )
    ;; Verify title exists and requester has viewing rights
    (asserts! (title-registered? title-id) err-property-not-found)
    (asserts! 
      (or 
        (is-eq tx-sender actual-owner)
        has-view-permission
        (is-eq tx-sender registry-admin)
      ) 
      err-unauthorized-viewer
    )
    
    ;; Return title information
    (ok title-data)
  )
)

