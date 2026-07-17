import { Body, Controller, Delete, Get, Post } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { AuthenticatedUser } from '../auth/auth.types';
import { CurrentUser } from '../auth/current-user.decorator';
import { Roles } from '../auth/roles.decorator';
import { JoinFamilyDto } from '../dto/join-family.dto';
import { FamilyService } from './family.service';

@ApiBearerAuth()
@ApiTags('families')
@Controller('families')
export class FamilyController {
  constructor(private readonly families: FamilyService) {}

  @Roles('child')
  @Post()
  create(@CurrentUser() user: AuthenticatedUser) {
    return this.families.create(user);
  }

  @Get('current')
  current(@CurrentUser() user: AuthenticatedUser) {
    return this.families.current(user);
  }

  @Roles('child')
  @Post('invitations')
  createInvitation(@CurrentUser() user: AuthenticatedUser) {
    return this.families.createInvitation(user);
  }

  @Roles('elder')
  @Post('join')
  join(@CurrentUser() user: AuthenticatedUser, @Body() body: JoinFamilyDto) {
    return this.families.join(user, body.code);
  }

  @Roles('elder')
  @Delete('current/membership')
  leave(@CurrentUser() user: AuthenticatedUser) {
    return this.families.leave(user);
  }
}
