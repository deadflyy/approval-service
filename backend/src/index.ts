import express from 'express';
import cors from 'cors';
import { initDatabase } from './database';
import authRoutes from './routes/auth';
import userRoutes from './routes/users';
import orgRoutes from './routes/organizations';
import templateRoutes from './routes/templates';
import requestRoutes from './routes/requests';
import batchNumberRoutes from './routes/batch-numbers';

const app = express();
const PORT = process.env.PORT || 3000;

app.use(cors());
app.use(express.json());

const db = initDatabase();
app.locals.db = db;

app.use('/api/auth', authRoutes);
app.use('/api/users', userRoutes);
app.use('/api/organizations', orgRoutes);
app.use('/api/templates', templateRoutes);
app.use('/api/requests', requestRoutes);
app.use('/api/batch-numbers', batchNumberRoutes);

app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});

export default app;
