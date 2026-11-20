import { Module } from '@nestjs/common';
import {
  CategoriesController,
  AdminCategoriesController,
} from './categories.controller';
import { CategoriesService } from './categories.service';
import { AdminAuthModule } from '../admin-auth/admin-auth.module';

@Module({
  imports: [AdminAuthModule],
  controllers: [CategoriesController, AdminCategoriesController],
  providers: [CategoriesService],
  exports: [CategoriesService],
})
export class CategoriesModule {}
