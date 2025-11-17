import { gql } from "apollo-server-express";

export const trainingTypeDefs = gql`
  """ Training program entity """
  type Training {
    id: ID!
    title: String!
    amount: Float!
    gst: Float!
    days: Int!
    totalAmount: Float!
    imagePath: String
    shortDescription: String
    fullDescription: String
    createdAt: String
    updatedAt: String
  }

  """ Real-time training update type (for subscriptions) """
  type TrainingNotification {
    action: String!          # e.g. "added", "updated", "deleted"
    training: Training!
    timestamp: String!
  }

  # ======================================================
  # 🧾 TRAINING ENROLLMENT TYPES
  # ======================================================
  """ Represents a student's enrollment in a training """
  type TrainingEnroll {
    id: ID!
    courseId: ID!
    courseTitle: String
    courseDays: Int
    totalAmount: Float
    name: String!
    email: String!
    phone: String!
    address: String!
    isTenthPass: Boolean
    isHaveLicence: Boolean
    isAbove18: Boolean
    status: String
    createdAt: String
    updatedAt: String
  }

  """ Input structure for training enrollment """
  input TrainingEnrollInput {
    courseId: ID!
    name: String!
    email: String!
    phone: String!
    address: String!
    isTenthPass: Boolean
    isHaveLicence: Boolean
    isAbove18: Boolean
  }

  # ======================================================
  # 📘 QUERY OPERATIONS
  # ======================================================
  type Query {
    """ Fetch all training programs (search + sort) """
    getTrainings(search: String, sortOrder: String): [Training]

    """ Fetch single training by ID """
    getTrainingById(id: ID!): Training

    """ (Admin) Fetch all training enrollments """
    getEnrollments: [TrainingEnroll]
  }

  # ======================================================
  # ✏️ MUTATION OPERATIONS
  # ======================================================
  type Mutation {
    """ Add a new training program """
    addTraining(
      title: String!
      amount: Float!
      gst: Float!
      days: Int!
      imagePath: String
      shortDescription: String
      fullDescription: String
    ): Training

    """ Update existing training details """
    updateTraining(
      id: ID!
      title: String
      amount: Float
      gst: Float
      days: Int
      imagePath: String
      shortDescription: String
      fullDescription: String
    ): Training

    """ Delete a training by ID """
    deleteTraining(id: ID!): String

    """ Enroll a student in a training program """
    enrollTraining(input: TrainingEnrollInput!): TrainingEnroll
  }

  # ======================================================
  # 🔔 SUBSCRIPTIONS (REAL-TIME UPDATES)
  # ======================================================
  type Subscription {
    """ Listen for new, updated, or deleted trainings """
    trainingUpdated: TrainingNotification
  }
`;
