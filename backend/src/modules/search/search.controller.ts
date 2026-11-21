import { Controller, Get, Query } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse } from '@nestjs/swagger';
import { SearchService } from './search.service';
import { SearchQueryDto } from './dto/search-query.dto';

@ApiTags('Search')
@Controller('search')
export class SearchController {
  constructor(private readonly searchService: SearchService) {}

  @Get()
  @ApiOperation({
    summary: 'Fuzzy search across listings with faceted filters',
  })
  @ApiResponse({ status: 200, description: 'Search results returned' })
  async search(@Query() queryDto: SearchQueryDto) {
    return this.searchService.searchListings(queryDto);
  }

  @Get('suggestions')
  @ApiOperation({
    summary: 'Fast autocomplete suggestions for categories and listing titles',
  })
  @ApiResponse({ status: 200, description: 'Search suggestions returned' })
  async suggestions(
    @Query('q') q?: string,
    @Query('categorySlug') categorySlug?: string,
    @Query('limit') limit?: string,
  ) {
    const parsedLimit = Math.min(Math.max(Number(limit) || 8, 1), 15);
    return this.searchService.getSuggestions(
      q ?? '',
      categorySlug,
      parsedLimit,
    );
  }
}
