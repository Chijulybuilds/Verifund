import express from "express";
import cors from "cors";
import helmet from "helmet";
import dotenv from "dotenv";

import deliveryRoutes from "./routes/delivery.routes";
import disputeRoutes from "./routes/verifyDispute";

dotenv.config();

const app = express();

app.use(express.json());
app.use(cors());
app.use(helmet());

/**
 * ROUTES
 */
app.use("/api/delivery", deliveryRoutes);

app.use("/api/dispute", disputeRoutes);

const PORT = process.env.PORT || 3000;

app.listen(PORT, () => {
    console.log(
        `Server running on port ${PORT}`
    );
});