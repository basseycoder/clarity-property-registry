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
