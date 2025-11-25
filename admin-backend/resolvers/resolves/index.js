import { droneResolvers } from "../Drone.resolver.js";
import { partResolvers } from "../Parts.resolver.js";
import { accessoryResolvers } from "../Accessories.resolver.js";
import { rentalResolvers } from "../Rental.resolver.js";

import { rentalBookingResolvers } from "../Buyer_Booking_Pilot_Rental.resolver.js";
import { droneRentalBookingResolvers } from "../Buyer_Booking_Drone_Rental.resolver.js";
import { SellerDroneRentalResolvers } from "../Seller_Drone_Rental.resolver.js";
import { hirePilotResolvers } from "../Hirepilot.resolver.js";
import { jobResolvers } from "../Hirejob.resolver.js";
import { orderResolvers } from "../Order.resolver.js";
import { returnResolvers } from "../Return.resolver.js";
import { serviceResolvers } from "../Service.resolver.js";
import { regulatoryResolvers } from "../Regulatory.resolver.js";
import { buyerResolvers } from "../Buyer.resolver.js";
import { sellerResolvers } from "../Seller.resolver.js";
import { notificationResolvers } from "../Notification.resolver.js";
import { trainingResolvers } from "../Training.resolver.js";
import { taxResolvers } from "../Tax.resolver.js";


export const resolves = [
  droneResolvers,
  partResolvers,
  accessoryResolvers,
  rentalResolvers,

  hirePilotResolvers,
  jobResolvers,
  orderResolvers,
  returnResolvers,
  serviceResolvers,
  regulatoryResolvers,
  buyerResolvers,
  sellerResolvers,
  taxResolvers,
  notificationResolvers,
  trainingResolvers,

  rentalBookingResolvers,
  droneRentalBookingResolvers,
  SellerDroneRentalResolvers,
];
