import Drone from "../models/Drone.js";
import Part from "../models/Parts.js";
import Accessory from "../models/Accessories.js";

export const marketplaceResolvers = {
  Query: {
    marketplace: async (_, { type }) => {
      let results = [];

      const mapDocs = (docs, category) =>
        docs.map((item) => ({
          id: item._id.toString(),
          name: item.name,
          brand: item.brand,
          price: item.price,
          description: item.description,
          image: item.image,
          category,
          status: item.status,
        }));

      try {
        switch (type.toLowerCase()) {
          case "drones":
            results = mapDocs(await Drone.find({ status: "approved" }), "drone");
            break;

          case "parts":
            results = mapDocs(await Part.find({ status: "approved" }), "part");
            break;

          case "accessories":
            results = mapDocs(await Accessory.find({ status: "approved" }), "accessory");
            break;

          case "all":
            const drones = mapDocs(await Drone.find({ status: "approved" }), "drone");
            const parts = mapDocs(await Part.find({ status: "approved" }), "part");
            const accessories = mapDocs(await Accessory.find({ status: "approved" }), "accessory");
            results = [...drones, ...parts, ...accessories];
            break;

          default:
            throw new Error("Invalid type. Use drones, parts, accessories, or all.");
        }

        return results;
      } catch (err) {
        console.error("❌ Error fetching marketplace data:", err);
        throw new Error("Failed to fetch marketplace data");
      }
    },
  },

  Mutation: {
    approveAllPending: async (_, { type }) => {
      try {
        let result;
        switch (type.toLowerCase()) {
          case "drones":
            result = await Drone.updateMany(
              { status: "pending" },
              { $set: { status: "approved" } }
            );
            break;
          case "parts":
            result = await Part.updateMany(
              { status: "pending" },
              { $set: { status: "approved" } }
            );
            break;
          case "accessories":
            result = await Accessory.updateMany(
              { status: "pending" },
              { $set: { status: "approved" } }
            );
            break;
          default:
            throw new Error("Invalid type. Use drones, parts, or accessories.");
        }

        return {
          success: true,
          type,
          count: result.modifiedCount || 0,
          message: `${result.modifiedCount} ${type} approved successfully.`,
        };
      } catch (err) {
        console.error("❌ Error approving pending items:", err);
        return { success: false, type, count: 0, message: "Error approving pending items" };
      }
    },
  },
};
