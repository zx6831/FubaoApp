import { CallHandler, ExecutionContext, Injectable, NestInterceptor } from '@nestjs/common';
import { Observable, tap } from 'rxjs';
import { PrismaService } from '../infrastructure/prisma.service';

@Injectable()
export class AuditInterceptor implements NestInterceptor {
  constructor(private readonly prisma: PrismaService) {}

  intercept(context: ExecutionContext, next: CallHandler): Observable<unknown> {
    const request = context.switchToHttp().getRequest();
    const method = String(request.method ?? '').toUpperCase();
    if (!['POST', 'PUT', 'PATCH', 'DELETE'].includes(method)) return next.handle();
    return next.handle().pipe(tap(() => void this.record(request, method)));
  }

  private async record(request: any, method: string) {
    if (!this.prisma.isEnabled()) return;
    const path = String(request.route?.path ?? request.path ?? 'unknown');
    const resourceType = path.split('/').filter(Boolean)[0] ?? 'unknown';
    await this.prisma.auditLog.create({
      data: {
        actorId: request.user?.sub ?? null,
        action: `${method.toLowerCase()}.${resourceType}`,
        resourceType,
        resourceId: request.params?.id ?? null,
        metadata: { path },
      },
    });
  }
}
