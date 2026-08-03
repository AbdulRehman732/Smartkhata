# Smart Khata Backend

AI-powered shop management FastAPI + MongoDB backend for Pakistani Kiryana store owners.

## Stack
- **Framework**: Python FastAPI
- **Database**: MongoDB (via Motor async driver, with `InMemoryDatabase` for 100% test isolation without requiring a live MongoDB daemon)
- **Machine Learning**: `scikit-learn` Linear Regression for 30-day restock demand forecasting
- **Voice Classifier**: Substring-based multi-lingual (Urdu, English, Punjabi) intent classifier + lazy OpenAI Whisper STT loader
- **Authentication**: JWT tokens with role-based access control (`owner` vs `employee`)

## Setup & Running

1. **Install Dependencies**:
```bash
pip install -r requirements.txt
```

2. **Run Server**:
```bash
uvicorn app.main:app --reload
```
Interactive API documentation is available at `http://127.0.0.1:8000/docs`.

3. **Run Tests**:
```bash
python -m pytest -v
```

## Tested vs Unverified
- **Verified (100% Test Coverage & Automated Assertions)**:
  - Auth & RBAC (403 restriction on employees for payroll, expenses, financial reports)
  - Inventory CRUD, Urdu/English search, low-stock filter, non-negative stock adjustments
  - Order processing with strict stock pre-validation across all line items before deduction
  - Customer Khata tracking, payments, and interleaved transaction history
  - Employee HR, daily attendance upsert on `(employee_id, date)`
  - Monthly salaried vs daily-rate payroll proration (leave days paid, half-day = 0.5 absence)
  - scikit-learn 30-day linear regression demand forecasting & threshold fallback rule
  - Multilingual AI intent classification & "restock" vs "stock" keyword collision safeguard
  - Incremental catalogue sync pull & push idempotency on `client_id` with per-order stock safety
  - ReportLab PDF invoice generation
- **Unverified (Environment Specific / Heavy Weight)**:
  - Whisper Speech-to-Text audio file upload endpoint (lazy loaded on demand, requires PyTorch and Whisper weights).
