-- Gmail was never needed for login (login uses comn_enrol_no + date_of_birth)
-- and its NOT NULL/unique constraint was blocking registration for admission
-- records that have no email on file.
ALTER TABLE "Register" DROP COLUMN "gmail";
