import uuid
from fastapi import APIRouter, HTTPException, status, Depends  # type: ignore
from app.models.schemas import UserRegister, UserLogin, TokenResponse
from app.database import get_database
from app.auth.security import hash_password, verify_password, create_access_token

router = APIRouter(prefix="/api/auth", tags=["Auth"])

@router.post("/register", response_model=TokenResponse)
async def register(user_data: UserRegister):
    db = get_database()
    existing = await db["users"].find_one({"username": user_data.username})
    if existing:
        raise HTTPException(status_code=400, detail="Username is already registered.")

    user_id = str(uuid.uuid4())
    doc = {
        "_id": user_id,
        "username": user_data.username,
        "hashed_password": hash_password(user_data.password),
        "name": user_data.name,
        "role": user_data.role.lower(),
        "employee_id": user_data.employee_id
    }
    await db["users"].insert_one(doc)

    token = create_access_token({"sub": user_id, "username": user_data.username, "role": doc["role"]})
    return TokenResponse(
        access_token=token,
        role=doc["role"],
        username=doc["username"],
        name=doc["name"]
    )

@router.post("/login", response_model=TokenResponse)
async def login(credentials: UserLogin):
    db = get_database()
    user = await db["users"].find_one({"username": credentials.username})
    if not user or not verify_password(credentials.password, user["hashed_password"]):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect username or password"
        )

    token = create_access_token({"sub": user["_id"], "username": user["username"], "role": user["role"]})
    return TokenResponse(
        access_token=token,
        role=user["role"],
        username=user["username"],
        name=user["name"]
    )
