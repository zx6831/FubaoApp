-- One child account and one elder account are allowed in each V1 family.
CREATE UNIQUE INDEX "FamilyMember_familyId_role_key"
ON "FamilyMember"("familyId", "role");
