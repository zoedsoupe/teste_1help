# **Bank**
![build](https://github.com/Mdsp9070/teste_1help/workflows/build/badge.svg?branch=main)
* [Session](#session)
  * [create](#session-create)
* [Transaction](#transaction)
  * [create](#transaction-create)
  * [show](#transaction-show)
  * [list](#transaction-list)
  * [delete](#transaction-delete)
* [User](#user)
  * [create](#user-create)
  * [show](#user-show)
  * [balance](#user-balance)
  * [change](#user-change)
  * [change_password](#user-change-password)
  * [create_recovery](#user-create-recovery)
  * [validate_recovery](#user-validate-recovery)
  * [recover_password](#user-recover-password)
  * [resend_confirmation_email](#user-resend-confirmation-email)
  * [confirm_email](#user-confirm-email)
# Session<a id=session></a>
## create<a id=session-create></a>
Returns token for this api
### Info
* __Method:__ POST
* __Path:__ /api/v1/login
### Body params

|Name|Description|Required?|Example|
|-|-|-|-|
|email|Account email|required||"mdsp@server.com"|
|password|Account password|required||"Somepass123"|
|password_confirmation|Current password confirmation|required||"Somepass123"|

### Example request
```
curl -H 'Content-type: application/json' \
     -X POST \
     'http://localhost:4000/api/v1/login'  \
     -d '{"email":"mdsp@server.com","password":"Somepass123","password_confirmation":"Somepass123"}'
```
### Exemple response
```json
{
  "data": {
    "token": "veryLongToken"
  },
  "message": "login_success"
}
```

---

# Transaction<a id=transaction></a>
## create<a id=transaction-create></a>
Creates a new Transaction between two accounts
### Info
* __Method:__ POST
* __Path:__ /api/v1/transactions
### Body params

|Name|Description|Required?|Example|
|-|-|-|-|
|amount|How much will be transferred|required||"865.89"|
|recipient_id|The recipient's unique identification|required||"UUID"|
|sender_id|The sender's unique identification|required||"UUID"|

### Example request
```
curl -H 'Authorization: Bearer VeryLongTokenJIUzUxMiIsInR5' \
     -H 'Content-type: application/json' \
     -X POST \
     'http://localhost:4000/api/v1/transactions'  \
     -d '{"amount":"865.89","recipient_id":"UUID","sender_id":"UUID"}'
```
### Exemple response
```json
{
  "data": {
    "id": "87ea5dfc-8b8e-384d-8489-79496e706390b497",
    "processing_date": "DATETIME",
    "recipient_id": "UUID",
    "sender_id": "UUID",
    "value": 1221
  },
  "message": "transferred"
}
```

---

## show<a id=transaction-show></a>
Get information about existing transaction
### Info
* __Method:__ GET
* __Path:__ /api/v1/transactions/:transaction_id
### Example request
```
curl -H 'Authorization: Bearer VeryLongTokenJIUzUxMiIsInR5' \
     -X GET \
     'http://localhost:4000/api/v1/transactions/89eadb93-a898-1055-6e1c-bcd6ab9ec0ad5675'
```
### Exemple response
```json
{
  "data": {
    "id": "87ea5dfc-8b8e-384d-8489-79496e706390b497",
    "processing_date": "DATETIME",
    "recipient_id": "UUID",
    "sender_id": "UUID",
    "value": 1200
  },
  "message": "found"
}
```

---

## list<a id=transaction-list></a>
List all transactions of logged in user given a intial and final date
### Info
* __Method:__ GET
* __Path:__ /api/v1/transactions
### Query params

|Name|Description|Required?|Example|
|-|-|-|-|
|final_date|Final date for searching transactions|optional||"DATETIME"|
|initial_date|Initial date for searching transactions|optional||"DATETIME"|

### Example request
```
curl -H 'Authorization: Bearer VeryLongTokenJIUzUxMiIsInR5' \
     -X GET \
     'http://localhost:4000/api/v1/transactions?final_date=DATETIME&initial_date=DATETIME'
```
### Exemple response
```json
{
  "data": [
    {
      "id": "87ea5dfc-8b8e-384d-8489-79496e706390b497",
      "processing_date": "DATETIME",
      "recipient_id": "UUID",
      "sender_id": "UUID",
      "value": 1200
    },
    {
      "id": "87ea5dfc-8b8e-384d-8489-79496e706390b497",
      "processing_date": "DATETIME",
      "recipient_id": "UUID",
      "sender_id": "UUID",
      "value": 1200
    },
    {
      "id": "87ea5dfc-8b8e-384d-8489-79496e706390b497",
      "processing_date": "DATETIME",
      "recipient_id": "UUID",
      "sender_id": "UUID",
      "value": 1200
    },
    {
      "id": "87ea5dfc-8b8e-384d-8489-79496e706390b497",
      "processing_date": "DATETIME",
      "recipient_id": "UUID",
      "sender_id": "UUID",
      "value": 1200
    },
    {
      "id": "87ea5dfc-8b8e-384d-8489-79496e706390b497",
      "processing_date": "DATETIME",
      "recipient_id": "UUID",
      "sender_id": "UUID",
      "value": 1200
    },
    {
      "id": "87ea5dfc-8b8e-384d-8489-79496e706390b497",
      "processing_date": "DATETIME",
      "recipient_id": "UUID",
      "sender_id": "UUID",
      "value": 1200
    },
    {
      "id": "87ea5dfc-8b8e-384d-8489-79496e706390b497",
      "processing_date": "DATETIME",
      "recipient_id": "UUID",
      "sender_id": "UUID",
      "value": 1200
    },
    {
      "id": "87ea5dfc-8b8e-384d-8489-79496e706390b497",
      "processing_date": "DATETIME",
      "recipient_id": "UUID",
      "sender_id": "UUID",
      "value": 1200
    }
  ],
  "message": "ok"
}
```

---

## delete<a id=transaction-delete></a>
Chargesback a transaction
### Info
* __Method:__ DELETE
* __Path:__ /api/v1/transactions/:transaction_id
### Example request
```
curl -H 'Authorization: Bearer VeryLongTokenJIUzUxMiIsInR5' \
     -X DELETE \
     'http://localhost:4000/api/v1/transactions/89eadb93-a898-1055-6e1c-bcd6ab9ec0ad5675'
```
### Exemple response
```json
{
  "message": "chargebacked"
}
```

---

# User<a id=user></a>
## create<a id=user-create></a>
Creates a new account
### Info
* __Method:__ POST
* __Path:__ /api/v1/users
### Body params

|Name|Description|Required?|Example|
|-|-|-|-|
|cnpj|Account CNPJ|required||"123.456.789/0001-12"|
|email|Account e-mail|required||"valid@email.com"|
|first_name|First name of the user|required||"some first_name"|
|last_name|Last name of the user|required||"some last_name"|
|mobile|Account mobile|required||"(dd)12345-6789"|
|new_password|New password to be set to that account|required||"NewPass123"|
|new_password_confirmation|New password confirmation|required||"NewPass123"|

### Example request
```
curl -H 'Content-type: application/json' \
     -X POST \
     'http://localhost:4000/api/v1/users'  \
     -d '{"cnpj":"123.456.789/0001-12","email":"valid@email.com","first_name":"some first_name","last_name":"some last_name","mobile":"(dd)12345-6789","new_password":"NewPass123","new_password_confirmation":"NewPass123"}'
```
### Exemple response
```json
{
  "data": {
    "cnpj": "123.456.789/0001-12",
    "email": "valid@email.com",
    "first_name": "Some First_name",
    "id": "87ea5dfc-8b8e-384d-8489-79496e706390b497",
    "last_name": "Some Last_name",
    "mobile": "(dd)12345-6789"
  },
  "message": "created"
}
```

---

## show<a id=user-show></a>
Get logged in user info
### Info
* __Method:__ GET
* __Path:__ /api/v1/users
### Example request
```
curl -H 'Authorization: Bearer VeryLongTokenJIUzUxMiIsInR5' \
     -X GET \
     'http://localhost:4000/api/v1/users'
```
### Exemple response
```json
{
  "data": {
    "cpf": "123.456.789-10",
    "email": "valid@email.com",
    "first_name": "matheus",
    "id": "87ea5dfc-8b8e-384d-8489-79496e706390b497",
    "last_name": "pessanha",
    "mobile": "(dd)12345-6789"
  },
  "message": "found"
}
```

---

## balance<a id=user-balance></a>
Get logged in user balance
### Info
* __Method:__ GET
* __Path:__ /api/v1/users/balance
### Example request
```
curl -H 'Authorization: Bearer VeryLongTokenJIUzUxMiIsInR5' \
     -X GET \
     'http://localhost:4000/api/v1/users/balance'
```
### Exemple response
```json
{
  "data": {
    "balance": "999999.99"
  },
  "message": "found"
}
```

---

## change<a id=user-change></a>
Basic user edition that they can do to themself
### Info
* __Method:__ PUT
* __Path:__ /api/v1/users/
### Body params

|Name|Description|Required?|Example|
|-|-|-|-|
|email|Account e-mail|optional||"new@email.com"|
|first_name|First name of the user|optional||"some updated first_name"|
|last_name|Last name of the user|optional||"some updated last_name"|

### Example request
```
curl -H 'Authorization: Bearer VeryLongTokenJIUzUxMiIsInR5' \
     -H 'Content-type: application/json' \
     -X PUT \
     'http://localhost:4000/api/v1/users/'  \
     -d '{"email":"new@email.com","first_name":"some updated first_name","last_name":"some updated last_name"}'
```
### Exemple response
```json
{
  "data": {
    "cpf": "123.456.789-10",
    "email": "new@email.com",
    "first_name": "Some Updated First_name",
    "id": "87ea5dfc-8b8e-384d-8489-79496e706390b497",
    "last_name": "Some Updated Last_name",
    "mobile": "(dd)12345-6789"
  },
  "message": "updated"
}
```

---

## change_password<a id=user-change-password></a>
Changes logged in user password
### Info
* __Method:__ PUT
* __Path:__ /api/v1/users/change-password
### Body params

|Name|Description|Required?|Example|
|-|-|-|-|
|new_password|New password to be set to that account|required||"NewPass123!"|
|new_password_confirmation|New password confirmation|required||"NewPass123!"|
|password|Current password, required to access this action|required||"Somepass123"|
|password_confirmation|Current password confirmation|required||"Somepass123"|

### Example request
```
curl -H 'Authorization: Bearer VeryLongTokenJIUzUxMiIsInR5' \
     -H 'Content-type: application/json' \
     -X PUT \
     'http://localhost:4000/api/v1/users/change-password'  \
     -d '{"new_password":"NewPass123!","new_password_confirmation":"NewPass123!","password":"Somepass123","password_confirmation":"Somepass123"}'
```
### Exemple response
```json
{
  "message": "password_changed"
}
```

---

## create_recovery<a id=user-create-recovery></a>
Creates password recovery attempt
### Info
* __Method:__ POST
* __Path:__ /api/v1/users/recover-password
### Body params

|Name|Description|Required?|Example|
|-|-|-|-|
|email|Account e-mail|required||"valid@email.com"|

### Example request
```
curl -H 'Content-type: application/json' \
     -X POST \
     'http://localhost:4000/api/v1/users/recover-password'  \
     -d '{"email":"valid@email.com"}'
```
### Exemple response
```json
{
  "message": "recovery_attempt_created"
}
```

---

## validate_recovery<a id=user-validate-recovery></a>
Validates token and returns user data if valid
### Info
* __Method:__ GET
* __Path:__ /api/v1/users/recover-password
### Query params

|Name|Description|Required?|Example|
|-|-|-|-|
|token|A token sent by email to authenticate this action|required||"VeryLongToken"|

### Example request
```
curl -X GET \
     'http://localhost:4000/api/v1/users/recover-password?token=VeryLongToken'
```
### Exemple response
```json
{
  "data": {
    "cpf": "123.456.789-10",
    "email": "valid@email.com",
    "first_name": "matheus",
    "id": "87ea5dfc-8b8e-384d-8489-79496e706390b497",
    "last_name": "pessanha",
    "mobile": "(dd)12345-6789"
  },
  "message": "valid"
}
```

---

## recover_password<a id=user-recover-password></a>
Sets new password for user
### Info
* __Method:__ PUT
* __Path:__ /api/v1/users/recover-password
### Body params

|Name|Description|Required?|Example|
|-|-|-|-|
|new_password|New password to be set to that account|required||"NewPass123!"|
|new_password_confirmation|New password confirmation|required||"NewPass123!"|
|token|A token sent by email to authenticate this action|required||"VeryLongToken"|

### Example request
```
curl -H 'Content-type: application/json' \
     -X PUT \
     'http://localhost:4000/api/v1/users/recover-password'  \
     -d '{"new_password":"NewPass123!","new_password_confirmation":"NewPass123!","token":"VeryLongToken"}'
```
### Exemple response
```json
{
  "message": "password_changed"
}
```

---

## resend_confirmation_email<a id=user-resend-confirmation-email></a>
Sends new confirmation email
### Info
* __Method:__ POST
* __Path:__ /api/v1/users/resend-confirmation-email
### Body params

|Name|Description|Required?|Example|
|-|-|-|-|
|email|Account e-mail|required||"valid@email.com"|

### Example request
```
curl -H 'Content-type: application/json' \
     -X POST \
     'http://localhost:4000/api/v1/users/resend-confirmation-email'  \
     -d '{"email":"valid@email.com"}'
```
### Exemple response
```json
{
  "message": "success"
}
```

---

## confirm_email<a id=user-confirm-email></a>
Activates the account related to given token
### Info
* __Method:__ GET
* __Path:__ /api/v1/users/confirm-email
### Query params

|Name|Description|Required?|Example|
|-|-|-|-|
|token|A token sent by email to authenticate this action|required||"VeryLongToken"|

### Example request
```
curl -X GET \
     'http://localhost:4000/api/v1/users/confirm-email?token=VeryLongToken'
```
### Exemple response
```json
{
  "message": "email_confirmed"
}
```

---

