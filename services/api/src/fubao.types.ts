export type Role = 'child' | 'elder';
export type TaskKind = 'medicine' | 'bloodPressure' | 'walk' | 'mood';

export interface DailyTask {
  id: string;
  kind: TaskKind;
  title: string;
  timeLabel: string;
  completedAt: string | null;
}

export interface HealthPlan {
  id: string;
  title: string;
  status: 'active' | 'paused';
  completed: number;
  total: number;
}

export interface CareAlert {
  id: string;
  level: 'L1' | 'L2';
  metric: string;
  message: string;
  createdAt: string;
}
