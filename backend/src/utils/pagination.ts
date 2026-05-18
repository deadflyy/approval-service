import Database from 'better-sqlite3';

export interface PaginationParams {
  page: number;
  pageSize: number;
  keyword?: string;
  [key: string]: any;
}

export interface PaginatedResponse<T> {
  data: T[];
  pagination: {
    page: number;
    pageSize: number;
    total: number;
    totalPages: number;
  };
}

export interface QueryBuilder {
  baseSql: string;
  countSql: string;
  conditions: string[];
  params: any[];
}

export function buildPaginatedQuery(
  db: Database.Database,
  tableName: string,
  selectFields: string,
  params: PaginationParams,
  filters: Record<string, any>,
  searchableFields: string[],
  joins: string = '',
  orderBy: string = 'created_at DESC'
): PaginatedResponse<any> {
  const { page, pageSize, keyword, ...filterParams } = params;

  // Validate pagination params
  const validPage = Math.max(1, page || 1);
  const validPageSize = [10, 20, 50, 100].includes(pageSize) ? pageSize : 20;

  // Build conditions
  const conditions: string[] = [];
  const queryParams: any[] = [];

  // Add filters
  for (const [key, value] of Object.entries(filters)) {
    if (value !== undefined && value !== null && value !== '') {
      conditions.push(`${key} = ?`);
      queryParams.push(value);
    }
  }

  // Add keyword search
  if (keyword && searchableFields.length > 0) {
    const searchConditions = searchableFields.map(field => `${field} LIKE ?`);
    conditions.push(`(${searchConditions.join(' OR ')})`);
    searchableFields.forEach(() => queryParams.push(`%${keyword}%`));
  }

  // Build WHERE clause
  const whereClause = conditions.length > 0 ? `WHERE ${conditions.join(' AND ')}` : '';

  // Get total count
  const countSql = `SELECT COUNT(*) as total FROM ${tableName} ${joins} ${whereClause}`;
  const { total } = db.prepare(countSql).get(...queryParams) as { total: number };

  // Calculate pagination
  const totalPages = Math.ceil(total / validPageSize);
  const offset = (validPage - 1) * validPageSize;

  // Get paginated data
  const dataSql = `${selectFields} FROM ${tableName} ${joins} ${whereClause} ORDER BY ${orderBy} LIMIT ? OFFSET ?`;
  const data = db.prepare(dataSql).all(...queryParams, validPageSize, offset);

  return {
    data,
    pagination: {
      page: validPage,
      pageSize: validPageSize,
      total,
      totalPages
    }
  };
}

export function validatePaginationParams(params: any): { valid: boolean; errors: string[] } {
  const errors: string[] = [];

  if (params.page !== undefined) {
    const page = Number(params.page);
    if (isNaN(page) || page < 1 || !Number.isInteger(page)) {
      errors.push('page 必须是大于 0 的整数');
    }
  }

  if (params.pageSize !== undefined) {
    const pageSize = Number(params.pageSize);
    if (![10, 20, 50, 100].includes(pageSize)) {
      errors.push('pageSize 必须是 10、20、50 或 100');
    }
  }

  return {
    valid: errors.length === 0,
    errors
  };
}
