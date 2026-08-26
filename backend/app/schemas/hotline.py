from datetime import datetime
from typing import Optional
from pydantic import BaseModel, ConfigDict

class HotlineBase(BaseModel):
    name: str
    phone: str
    email: Optional[str] = None
    description: Optional[str] = None
    category: str = "national"  # 'campus' | 'national' | 'emergency'
    type: str = "call"  # 'call' | 'sms'
    is_active: bool = True
    sort_order: int = 0

class HotlineCreate(HotlineBase):
    pass

class HotlineUpdate(BaseModel):
    name: Optional[str] = None
    phone: Optional[str] = None
    email: Optional[str] = None
    description: Optional[str] = None
    category: Optional[str] = None
    type: Optional[str] = None
    is_active: Optional[bool] = None
    sort_order: Optional[int] = None

class HotlineRead(HotlineBase):
    id: str
    created_at: datetime
    updated_at: datetime

    model_config = ConfigDict(from_attributes=True)
