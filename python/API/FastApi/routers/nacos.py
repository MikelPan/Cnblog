from fastapi import APIRouter

router = APIRouter()


@router.get("/nacos/")
async def read_nacos():
    return [{"username": "Foo"}, {"username": "Bar"}]


@router.get("/nacos/me")
async def read_user_me():
    return {"username": "fakecurrentuser"}


@router.get("/nacos/{username}")
async def read_user(username: str):
    return {"username": username}


