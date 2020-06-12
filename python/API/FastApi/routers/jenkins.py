from fastapi import APIRouter

router = APIRouter()


@router.get("/jobs/")
async def read_users():
    return [{"username": "Foo"}, {"username": "Bar"}]


@router.get("/jobs/me")
async def read_user_me():
    return {"username": "fakecurrentuser"}


@router.get("/jobs/{username}")
async def read_user(username: str):
    return {"username": username}


