import { Controller, Get, Param, Query } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse } from '@nestjs/swagger';
import { HomeService } from './home.service';
import { HomeQueryDto } from './dto/home-query.dto';

@ApiTags('Home')
@Controller('home')
export class HomeController {
  constructor(private readonly homeService: HomeService) {}

  @Get()
  @ApiOperation({
    summary:
      'Get aggregated Home Feed (categories, featured, latest, recommended, promotions)',
  })
  @ApiResponse({ status: 200, description: 'Aggregated home feed returned' })
  async getHomeFeed(@Query() query: HomeQueryDto) {
    return this.homeService.getHomeFeed(query);
  }

  @Get('featured')
  @ApiOperation({ summary: 'Get featured/promoted products' })
  @ApiResponse({ status: 200, description: 'Featured products returned' })
  async getFeatured(@Query() query: HomeQueryDto) {
    return this.homeService.getFeaturedListings(query);
  }

  @Get('latest')
  @ApiOperation({ summary: 'Get latest published products' })
  @ApiResponse({ status: 200, description: 'Latest products returned' })
  async getLatest(@Query() query: HomeQueryDto) {
    return this.homeService.getLatestListings(query);
  }

  @Get('recommended')
  @ApiOperation({ summary: 'Get recommended products based on engagement' })
  @ApiResponse({ status: 200, description: 'Recommended products returned' })
  async getRecommended(@Query() query: HomeQueryDto) {
    return this.homeService.getRecommendedListings(query);
  }

  @Get('categories')
  @ApiOperation({
    summary:
      'Get popular root categories with subcategories and listing counts',
  })
  @ApiResponse({ status: 200, description: 'Popular categories returned' })
  async getPopularCategories() {
    return this.homeService.getPopularCategories();
  }

  @Get('sections/:sectionSlug')
  @ApiOperation({
    summary:
      'Get server-driven Section Home Feed (subcategories, promotions, live previews, featured, latest, providers, filterConfig)',
  })
  @ApiResponse({ status: 200, description: 'Section home feed returned' })
  @ApiResponse({ status: 404, description: 'Section not found' })
  async getSectionHome(
    @Param('sectionSlug') sectionSlug: string,
    @Query() query: HomeQueryDto,
  ) {
    return this.homeService.getSectionHome(sectionSlug, query);
  }
}
