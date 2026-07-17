import {
  ArgumentsHost,
  Catch,
  ExceptionFilter,
  HttpException,
  HttpStatus,
} from '@nestjs/common';
import { HttpAdapterHost } from '@nestjs/core';

@Catch()
export class AllExceptionsFilter implements ExceptionFilter {
  constructor(private readonly adapterHost: HttpAdapterHost) {}

  catch(exception: unknown, host: ArgumentsHost): void {
    const status =
      exception instanceof HttpException
        ? exception.getStatus()
        : HttpStatus.INTERNAL_SERVER_ERROR;
    const message = this.messageFor(exception, status);
    const { httpAdapter } = this.adapterHost;
    const context = host.switchToHttp();

    httpAdapter.reply(
      context.getResponse(),
      { code: status, msg: message, data: null },
      status,
    );
  }

  private messageFor(exception: unknown, status: number): string {
    if (!(exception instanceof HttpException)) {
      return '服务器内部错误';
    }
    const response = exception.getResponse();
    if (typeof response === 'string') return response;
    if (typeof response === 'object' && response !== null && 'message' in response) {
      const message = (response as { message: string | string[] }).message;
      return Array.isArray(message) ? message.join('；') : message;
    }
    return HttpStatus[status] ?? '请求失败';
  }
}
