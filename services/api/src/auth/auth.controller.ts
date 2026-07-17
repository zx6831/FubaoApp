import { Body, Controller, HttpCode, Post } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { CurrentUser } from './current-user.decorator';
import { AuthenticatedUser } from './auth.types';
import { AuthService } from './auth.service';
import { RefreshTokenDto } from './dto/refresh-token.dto';
import { RequestCodeDto } from './dto/request-code.dto';
import { VerifyCodeDto } from './dto/verify-code.dto';
import { Public } from './public.decorator';

@ApiTags('authentication')
@Controller('auth')
export class AuthController {
  constructor(private readonly auth: AuthService) {}

  @Public()
  @Post('request-code')
  requestCode(@Body() body: RequestCodeDto) {
    return this.auth.requestCode(body.phone);
  }

  @Public()
  @Post('verify-code')
  verifyCode(@Body() body: VerifyCodeDto) {
    return this.auth.verifyCode(body.phone, body.code, body.role);
  }

  @Public()
  @HttpCode(200)
  @Post('refresh')
  refresh(@Body() body: RefreshTokenDto) {
    return this.auth.refresh(body.refreshToken);
  }

  @ApiBearerAuth()
  @HttpCode(200)
  @Post('logout')
  logout(@CurrentUser() user: AuthenticatedUser, @Body() body: RefreshTokenDto) {
    return this.auth.logout(user.sub, body.refreshToken);
  }
}
