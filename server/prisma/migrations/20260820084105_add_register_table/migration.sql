-- CreateTable
CREATE TABLE "Register" (
    "id" SERIAL NOT NULL,
    "comn_enrol_no" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "gmail" TEXT NOT NULL,
    "password" TEXT NOT NULL,

    CONSTRAINT "Register_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "Register_comn_enrol_no_key" ON "Register"("comn_enrol_no");
