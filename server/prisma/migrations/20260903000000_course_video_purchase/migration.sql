-- CreateTable
CREATE TABLE "CourseVideoPurchase" (
    "id" SERIAL NOT NULL,
    "comn_enrol_no" TEXT NOT NULL,
    "video_key" TEXT NOT NULL,
    "razorpay_order_id" TEXT NOT NULL,
    "razorpay_payment_id" TEXT NOT NULL,
    "amount" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "CourseVideoPurchase_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "CourseVideoPurchase_razorpay_payment_id_key" ON "CourseVideoPurchase"("razorpay_payment_id");

-- CreateIndex
CREATE INDEX "CourseVideoPurchase_comn_enrol_no_idx" ON "CourseVideoPurchase"("comn_enrol_no");

-- CreateIndex
CREATE UNIQUE INDEX "CourseVideoPurchase_comn_enrol_no_video_key_key" ON "CourseVideoPurchase"("comn_enrol_no", "video_key");
