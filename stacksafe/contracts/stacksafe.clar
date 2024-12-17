;; StackSafe Vault - Secure time-locked asset storage with yield farming
;; Error codes
(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-ALREADY-INITIALIZED (err u101))
(define-constant ERR-NOT-INITIALIZED (err u102))
(define-constant ERR-LOCK-ACTIVE (err u103))
(define-constant ERR-INSUFFICIENT-SIGNATURES (err u104))
(define-constant ERR-INVALID-BENEFICIARY (err u105))
(define-constant ERR-LOCK-EXPIRED (err u106))
(define-constant ERR-YIELD-FARMING-ACTIVE (err u112))
(define-constant ERR-NO-YIELD-FARMING (err u113))
(define-constant ERR-INSUFFICIENT-BALANCE (err u114))

;; Data vars
(define-data-var contract-owner principal tx-sender)
(define-data-var lock-until uint u0)
(define-data-var required-signatures uint u0)
(define-data-var beneficiary (optional principal) none)
(define-data-var vault-balance uint u0)
(define-data-var current-signature-count uint u0)
(define-data-var withdrawal-id uint u0)
(define-data-var yield-farming-active bool false)
(define-data-var total-yield-earned uint u0)
(define-data-var yield-rate uint u5) ;; 5% annual yield rate (can be updated by owner)

;; Data maps
(define-map authorized-signers principal bool)
(define-map withdrawal-signatures {signer: principal, id: uint} bool)
(define-map token-balances principal uint)
(define-map yield-positions 
    principal 
    {amount: uint, start-height: uint, last-claim-height: uint})

;; Read-only functions
(define-read-only (get-lock-expiry)
    (var-get lock-until))

(define-read-only (get-vault-balance)
    (var-get vault-balance))

(define-read-only (get-token-balance (token-owner principal))
    (default-to u0 (map-get? token-balances token-owner)))

(define-read-only (get-withdrawal-id)
    (var-get withdrawal-id))

(define-read-only (get-current-signature-count)
    (var-get current-signature-count))

(define-read-only (is-authorized-signer (account principal))
    (default-to false (map-get? authorized-signers account)))

(define-read-only (is-contract-owner)
    (is-eq tx-sender (var-get contract-owner)))

(define-read-only (has-signed (signer principal))
    (default-to 
        false 
        (map-get? withdrawal-signatures {signer: signer, id: (var-get withdrawal-id)})))

(define-read-only (get-yield-farming-status)
    (var-get yield-farming-active))

(define-read-only (get-total-yield-earned)
    (var-get total-yield-earned))

(define-read-only (get-yield-position (user principal))
    (map-get? yield-positions user))

;; Calculate accrued yield for a position
(define-read-only (calculate-yield (amount uint) (blocks uint))
    (let (
        (annual-blocks u52560) ;; Approximately number of blocks in a year
        (yield-amount (/ (* (* amount (var-get yield-rate)) blocks) (* annual-blocks u100))))
        yield-amount))

;; Initialize vault
(define-public (initialize-vault (lock-period uint) (sig-threshold uint) (beneficiary-address (optional principal)))
    (let ((sender tx-sender))
        (asserts! (is-contract-owner) ERR-NOT-AUTHORIZED)
        (asserts! (is-eq (var-get lock-until) u0) ERR-ALREADY-INITIALIZED)
        (asserts! (> lock-period u0) (err u107))
        (asserts! (> sig-threshold u0) (err u108))
        
        (var-set lock-until (+ block-height lock-period))
        (var-set required-signatures sig-threshold)
        (var-set beneficiary beneficiary-address)
        (ok true)))

;; Add authorized signer
(define-public (add-signer (new-signer principal))
    (begin
        (asserts! (is-contract-owner) ERR-NOT-AUTHORIZED)
        (map-set authorized-signers new-signer true)
        (ok true)))

;; Remove authorized signer
(define-public (remove-signer (signer principal))
    (begin
        (asserts! (is-contract-owner) ERR-NOT-AUTHORIZED)
        (map-delete authorized-signers signer)
        (ok true)))

;; Deposit STX
(define-public (deposit-stx (amount uint))
    (begin
        (asserts! (> amount u0) (err u109))
        (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))
        (var-set vault-balance (+ (var-get vault-balance) amount))
        (ok true)))

;; Start yield farming
(define-public (start-yield-farming (amount uint))
    (let (
        (current-balance (var-get vault-balance))
        (existing-position (get-yield-position tx-sender)))
        
        (asserts! (> amount u0) (err u109))
        (asserts! (>= current-balance amount) ERR-INSUFFICIENT-BALANCE)
        (asserts! (is-none existing-position) ERR-YIELD-FARMING-ACTIVE)
        
        (map-set yield-positions 
            tx-sender 
            {amount: amount, 
             start-height: block-height,
             last-claim-height: block-height})
        
        (var-set vault-balance (- current-balance amount))
        (var-set yield-farming-active true)
        (ok true)))

;; Claim yield
(define-public (claim-yield)
    (let (
        (position (unwrap! (get-yield-position tx-sender) ERR-NO-YIELD-FARMING))
        (amount (get amount position))
        (last-height (get last-claim-height position))
        (blocks-passed (- block-height last-height))
        (yield-amount (calculate-yield amount blocks-passed)))
        
        (asserts! (> blocks-passed u0) ERR-NO-YIELD-FARMING)
        
        (map-set yield-positions
            tx-sender
            (merge position {last-claim-height: block-height}))
        
        (var-set total-yield-earned (+ (var-get total-yield-earned) yield-amount))
        (var-set vault-balance (+ (var-get vault-balance) yield-amount))
        (ok yield-amount)))

;; End yield farming position
(define-public (end-yield-farming)
    (let (
        (position (unwrap! (get-yield-position tx-sender) ERR-NO-YIELD-FARMING))
        (amount (get amount position))
        (last-height (get last-claim-height position))
        (blocks-passed (- block-height last-height))
        (final-yield (calculate-yield amount blocks-passed)))
        
        ;; Return principal and final yield
        (map-delete yield-positions tx-sender)
        (var-set vault-balance (+ (var-get vault-balance) amount final-yield))
        (var-set total-yield-earned (+ (var-get total-yield-earned) final-yield))
        (var-set yield-farming-active false)
        (ok (+ amount final-yield))))

;; Sign withdrawal
(define-public (sign-withdrawal)
    (begin
        (asserts! (is-authorized-signer tx-sender) ERR-NOT-AUTHORIZED)
        (asserts! (not (has-signed tx-sender)) (err u111))
        (map-set withdrawal-signatures 
                 {signer: tx-sender, id: (var-get withdrawal-id)} 
                 true)
        (var-set current-signature-count (+ (var-get current-signature-count) u1))
        (ok true)))

;; Start new withdrawal round
(define-public (start-withdrawal)
    (begin
        (asserts! (is-contract-owner) ERR-NOT-AUTHORIZED)
        (var-set withdrawal-id (+ (var-get withdrawal-id) u1))
        (var-set current-signature-count u0)
        (ok true)))

;; Withdraw funds
(define-public (withdraw (amount uint))
    (let ((current-balance (var-get vault-balance)))
        (asserts! (>= current-balance amount) (err u110))
        (asserts! (or 
            (and 
                (>= block-height (var-get lock-until))
                (>= (var-get current-signature-count) (var-get required-signatures)))
            (is-beneficiary-emergency)) ERR-LOCK-ACTIVE)
        
        (try! (as-contract (stx-transfer? amount tx-sender (var-get contract-owner))))
        (var-set vault-balance (- current-balance amount))
        (ok true)))

;; Check if beneficiary emergency withdrawal is valid
(define-private (is-beneficiary-emergency)
    (let ((current-beneficiary (var-get beneficiary)))
        (match current-beneficiary
            beneficiary-principal (and 
                (is-eq tx-sender beneficiary-principal)
                (> block-height (+ (var-get lock-until) u52560)))
            false)))

;; Update beneficiary
(define-public (update-beneficiary (new-beneficiary (optional principal)))
    (begin
        (asserts! (is-contract-owner) ERR-NOT-AUTHORIZED)
        (var-set beneficiary new-beneficiary)
        (ok true)))

;; Transfer ownership
(define-public (transfer-ownership (new-owner principal))
    (begin
        (asserts! (is-contract-owner) ERR-NOT-AUTHORIZED)
        (var-set contract-owner new-owner)
        (ok true)))

;; Update yield rate (only owner)
(define-public (update-yield-rate (new-rate uint))
    (begin
        (asserts! (is-contract-owner) ERR-NOT-AUTHORIZED)
        (asserts! (<= new-rate u100) (err u115))
        (var-set yield-rate new-rate)
        (ok true)))