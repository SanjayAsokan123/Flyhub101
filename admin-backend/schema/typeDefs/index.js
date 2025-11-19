// typeDefs/index.js

import { baseTypeDefs } from "./baseTypeDefs.js";
import { droneTypeDefs } from "../Drone.schema.js";
import { partTypeDefs } from "../Parts.schema.js";
import { accessoryTypeDefs } from "../Accessories.schema.js";
import { rentalTypeDefs } from "../Rental.schema.js";
import { rentalBookingTypeDefs }  from "../Buyer_Booking_Pilot_Rental.schema.js";
import { dronerentalBookingTypeDefs } from "../Buyer_Booking_Drone_Rental.schema.js";
import { hirePilotTypeDefs } from "../Hirepilot.schema.js";
import { jobTypeDefs } from "../Hirejob.schema.js";
import { orderTypeDefs } from "../Order.schema.js";
import { returnTypeDefs } from "../Return.schema.js";
import { serviceTypeDefs } from "../Service.schema.js";
import { regulatoryTypeDefs } from "../Regulatory.schema.js";
import { buyerTypeDefs } from "../Buyer.schema.js";
import { sellerTypeDefs } from "../Seller.schema.js";
import { notificationTypeDefs } from "../Notification.schema.js";
import { trainingTypeDefs } from "../Training.schema.js"; // ✅ Added Training schema
import { taxTypeDefs } from "../Tax.schema.js";
// ✅ Export all typeDefs for Apollo Server
export const typeDefs = [
  baseTypeDefs,
  droneTypeDefs,
  partTypeDefs,
  accessoryTypeDefs,
  rentalTypeDefs,
  hirePilotTypeDefs,
  jobTypeDefs,
  orderTypeDefs,
  returnTypeDefs,
  serviceTypeDefs,
  regulatoryTypeDefs,
  buyerTypeDefs,
  sellerTypeDefs,
  taxTypeDefs,
  notificationTypeDefs,
  trainingTypeDefs, // ✅ Include here
  rentalBookingTypeDefs,
  dronerentalBookingTypeDefs,
];
