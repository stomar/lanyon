require "lanyon"

# Rack middleware
use Rack::Runtime

run Lanyon.application
