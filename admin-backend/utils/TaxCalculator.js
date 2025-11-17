import { Tax } from "../models/tax.model.js";

// get latest tax and compute tax multiplier
export async function calculateFinalPrice(basePrice) {
  const latestTax = await Tax.findOne().sort({ createdAt: -1 });
    console.log(`latestTax: ${latestTax}`);
  const sgst = latestTax?.sgst || 5;
  const commission = latestTax?.commission || 5;

  const totalTaxPercent = sgst + commission;
  const taxAmount = (basePrice * totalTaxPercent) / 100;
  const finalPrice = basePrice + taxAmount;

  return { finalPrice };
}