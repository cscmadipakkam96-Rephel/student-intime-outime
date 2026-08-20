-- Replace password-based login with date-of-birth-based login
ALTER TABLE "Register" ADD COLUMN "date_of_birth" TIMESTAMP(3);
ALTER TABLE "Register" DROP COLUMN "password";
