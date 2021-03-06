--
-- Caculates the yearly degree distributions for domestic airports from 1990 to 2009.
--
-- USAGE:
--
-- local mode
-- pig -x local -p FLIGHT_EDGES=/path/to/flights_with_colnames.tsv -p DEG_DIST=/path/to/output degree_distribution.pig
--
-- hadoop mode
-- pig -p FLIGHT_EDGES=/path/to/flights_with_colnames.tsv -p DEG_DIST=/path/to/output degree_distribution.pig
--

-- Load data (boring part)
flight_edges = LOAD '$FLIGHT_EDGES' AS (origin_code:chararray, destin_code:chararray, origin_city:chararray, destin_city:chararray, passengers:int, seats:int, flights:int, distance:float, month:int, origin_pop:int, destin_pop:int);
--

-- Cut off all monthly data portion, we'll sum everything for a whole year in the next step
year_data     = FOREACH flight_edges {
                  year = (int)month/(int)100;
                  GENERATE
                    origin_code AS origin_code,
                    destin_code AS destin_code,
                    passengers  AS passengers,
                    seats       AS seats,
                    flights     AS flights,
                    year        AS year
                  ;
                };

-- For every (airport,month) pair get passengers, seats, and flights out
edges_out     = FOREACH year_data GENERATE
                  origin_code AS airport,
                  year        AS year,
                  passengers  AS passengers_out,
                  seats       AS seats_out,
                  flights     AS flights_out
                ;

-- For every (airport,month) pair get passengers, seats, and flights in
edges_in      = FOREACH year_data GENERATE
                  destin_code AS airport,
                  year        AS year,
                  passengers  AS passengers_in,
                  seats       AS seats_in,
                  flights     AS flights_in
                ;

-- group them together and sum
grouped_edges = COGROUP edges_in BY (airport,year), edges_out BY (airport,year);
degree_dist   = FOREACH grouped_edges {
                  passenger_degree = SUM(edges_in.passengers_in) + SUM(edges_out.passengers_out);
                  seats_degree     = SUM(edges_in.seats_in)      + SUM(edges_out.seats_out);
                  flights_degree   = SUM(edges_in.flights_in)    + SUM(edges_out.flights_out);
                  GENERATE
                    FLATTEN(group)   AS (airport, year),
                    passenger_degree AS passenger_degree,
                    seats_degree     AS seats_degree,
                    flights_degree   AS flights_degree
                  ;
                };

STORE degree_dist INTO '$DEG_DIST';
