from pydantic import BaseModel, EmailStr, Field


class LoginRequest(BaseModel):
    email: EmailStr
    password: str = Field(min_length=6, max_length=128)


class TokenPair(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"


class RefreshRequest(BaseModel):
    refresh_token: str


class ChangePasswordRequest(BaseModel):
    current_password: str = Field(min_length=6, max_length=128)
    new_password: str = Field(min_length=8, max_length=128)


class TenantInfo(BaseModel):
    id: str
    name: str
    status: str
    is_active: bool


class UserMe(BaseModel):
    id: str
    email: EmailStr
    full_name: str
    is_active: bool
    role: str
    tenant: TenantInfo | None = None


class SignupRequest(BaseModel):
    business_name: str = Field(min_length=2, max_length=255)
    full_name: str = Field(min_length=2, max_length=255)
    email: EmailStr
    password: str = Field(min_length=8, max_length=128)
    contact_phone: str | None = Field(default=None, max_length=32)


class SignupResponse(BaseModel):
    tenant_id: str
    message: str = "Kayıt alındı. Platform yöneticisi onayından sonra giriş yapabilirsiniz."
