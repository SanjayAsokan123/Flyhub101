import { bucket } from "../config/firebaseAdmin.js";
import { v4 as uuidv4 } from "uuid";

/* ------------------------------------------------------------------
   ⚙️ Configuration
------------------------------------------------------------------ */
const MAX_FILE_SIZE = 20 * 1024 * 1024; // 20 MB
const ALLOWED_TYPES = [
  "image/jpeg",
  "image/png",
  "image/webp",
  "application/pdf",
  "video/mp4",
  "application/msword",
  "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
];

/* ------------------------------------------------------------------
   📤 Upload Single File (Universal)
------------------------------------------------------------------ */
/**
 * Upload a single file (image, pdf, etc.) to Firebase Storage
 * @param {Object} file - Multer file object (with buffer, mimetype, originalname)
 * @param {String} folder - Target Firebase folder (e.g., "training", "hire-pilots")
 * @returns {Promise<String>} - Public URL of uploaded file
 */
export const uploadSingleFile = async (file, folder = "uploads") => {
  try {
    if (!file || !file.buffer) throw new Error("Invalid file: missing buffer");
    if (!bucket) throw new Error("Firebase Storage bucket not initialized");

    // ✅ Validate file size and type
    if (file.size > MAX_FILE_SIZE)
      throw new Error("File too large (max 20 MB)");
    if (!ALLOWED_TYPES.includes(file.mimetype))
      throw new Error(`Invalid file type: ${file.mimetype}`);

    // ✅ Create a unique, safe filename
    const uniqueId = uuidv4();
    const safeName = file.originalname.replace(/[^\w.\-]+/g, "_");
    const fileName = `${folder}/${uniqueId}_${safeName}`;
    const blob = bucket.file(fileName);

    // ✅ Upload to Firebase Storage
    await blob.save(file.buffer, {
      metadata: {
        contentType: file.mimetype,
        metadata: { firebaseStorageDownloadTokens: uniqueId },
      },
      resumable: false,
      gzip: true,
    });

    // ✅ Generate Public URL
    const publicUrl = `https://firebasestorage.googleapis.com/v0/b/${
      bucket.name
    }/o/${encodeURIComponent(fileName)}?alt=media&token=${uniqueId}`;

    console.log(`✅ Uploaded: ${fileName}`);
    return publicUrl;
  } catch (err) {
    console.error("❌ Firebase upload failed:", err.message);
    throw new Error("Upload to Firebase failed: " + err.message);
  }
};

/* ------------------------------------------------------------------
   📦 Upload Multiple Files
------------------------------------------------------------------ */
/**
 * Upload multiple files (e.g., certificates, gallery images, etc.)
 * @param {Array<Object>} files - Array of Multer file objects
 * @param {String} folder - Target folder
 * @returns {Promise<String[]>} - Array of public URLs
 */
export const uploadMultipleFiles = async (files, folder = "uploads") => {
  try {
    if (!Array.isArray(files) || files.length === 0)
      throw new Error("No files provided for upload");

    const uploadPromises = files.map((file) => uploadSingleFile(file, folder));
    return await Promise.all(uploadPromises);
  } catch (err) {
    console.error("❌ Error uploading multiple files:", err.message);
    throw new Error("Failed to upload multiple files: " + err.message);
  }
};

/* ------------------------------------------------------------------
   🗑️ Delete File (Auto-Cleanup)
------------------------------------------------------------------ */
/**
 * Delete a Firebase file (accepts public URL or internal path)
 * @param {String} filePathOrUrl
 * @returns {Promise<void>}
 */
export const deleteFirebaseFile = async (filePathOrUrl) => {
  try {
    if (!filePathOrUrl) throw new Error("No file path provided");
    if (!bucket) throw new Error("Firebase Storage bucket not initialized");

    // ✅ Extract internal storage path if a public URL is provided
    const decodedPath = decodeURIComponent(filePathOrUrl);
    const match = decodedPath.match(/\/o\/(.*?)\?/);
    const internalPath = match ? match[1] : filePathOrUrl;

    const file = bucket.file(internalPath);
    await file.delete({ ignoreNotFound: true });

    console.log(`🗑️ Deleted from Firebase: ${internalPath}`);
  } catch (err) {
    console.error("⚠️ Error deleting Firebase file:", err.message);
  }
};

/* ------------------------------------------------------------------
   🧩 Backward Compatibility
------------------------------------------------------------------ */
// Legacy support for older import syntax: { uploadToFirebase }
export const uploadToFirebase = uploadSingleFile;
