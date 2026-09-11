-- CreateTable
CREATE TABLE "ReminderLog" (
    "id" SERIAL NOT NULL,
    "comn_enrol_no" TEXT NOT NULL,
    "date" TEXT NOT NULL,
    "type" TEXT NOT NULL,

    CONSTRAINT "ReminderLog_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "ReminderLog_comn_enrol_no_date_type_key" ON "ReminderLog"("comn_enrol_no", "date", "type");
