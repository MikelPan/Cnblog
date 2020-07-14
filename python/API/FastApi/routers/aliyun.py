from fastapi import APIRouter

router = APIRouter()


@router.get("/aliyun/{Resources_Name}/list")
async def get_ecs_list(Resources_Name: str):
    
    return {"username": "Foo"}, {"username": "Bar"}


@router.get("/aliyun/{Resources_Name}/describe")
async def read_user_me():
    return {"username": "fakecurrentuser"}


@router.get("/aliyun/{Resources_Name}/")
async def read_user(username: str):
    return {"username": username}