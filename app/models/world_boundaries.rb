
@@countries = [
   "Algeria", "Bahrain", "Egypt", "Iran", "Iraq", "Israel", "Jordan", "Kuwait", "Lebanon", "Libya",
   "Mauritania", "Morocco", "Oman", "Palestine", "Qutar", "Saudi Arabia", "Syria", "Tunesia",
   "Turkey", "United Arab Emirates", "Yemen"
]

class Pointed
  attr_accessor :x, :y
  def initialize(x,y)
    @x = x
    @y = y
  end
end

#
# http://jakescruggs.blogspot.com/2009/07/point-inside-polygon-in-ruby.html
# http://github.com/fragility/spatial_adapter
#
class WorldBoundaries < ActiveRecord::Base

  def self.old_contains_point?(polygon,point)
    c = false
    i = -1
    j = polygon.size - 1
    while (i += 1) < polygon.size
      if ((polygon[i].y <= point.y && point.y < polygon[j].y) || 
         (polygon[j].y <= point.y && point.y < polygon[i].y))
        if (point.x < (polygon[j].x - polygon[i].x) * (point.y - polygon[i].y) / 
                      (polygon[j].y - polygon[i].y) + polygon[i].x)
          c = !c
        end
      end
      j = i
    end
    return c
  end

  def self.contains_point?(polygon,point)
    contains_point = false
    i = -1
    j = polygon.length - 1
    while (i += 1) < polygon.length
      a_point_on_polygon = polygon[i]
      trailing_point_on_polygon = polygon[j]
      if point_is_between_the_ys_of_the_line_segment?(point, a_point_on_polygon, trailing_point_on_polygon)
        if ray_crosses_through_line_segment?(point, a_point_on_polygon, trailing_point_on_polygon)
          contains_point = !contains_point
        end
      end
      j = i
    end
    return contains_point
  end

  def self.point_is_between_the_ys_of_the_line_segment?(point, a_point_on_polygon, trailing_point_on_polygon)
    (a_point_on_polygon.y <= point.y && point.y < trailing_point_on_polygon.y) ||
    (trailing_point_on_polygon.y <= point.y && point.y < a_point_on_polygon.y)
  end

  def self.ray_crosses_through_line_segment?(point, a_point_on_polygon, trailing_point_on_polygon)
    (point.x < (trailing_point_on_polygon.x - a_point_on_polygon.x) * (point.y - a_point_on_polygon.y) /
             (trailing_point_on_polygon.y - a_point_on_polygon.y) + a_point_on_polygon.x)
  end

  def self.outside_bounding_box?(point)
    bb_point_1, bb_point_2 = bounding_box
    max_x = [bb_point_1.x, bb_point_2.x].max
    max_y = [bb_point_1.y, bb_point_2.y].max
    min_x = [bb_point_1.x, bb_point_2.x].min
    min_y = [bb_point_1.y, bb_point_2.y].min
    point.x < min_x || point.x > max_x || point.y < min_y || point.y > max_y
  end

  def self.polygon_country(country_name)
    country = WorldBoundaries.find(:first, :conditions => [ "name ILIKE ?", "%#{country_name}%" ] );
    return country
  end

  def self.polygon_inside?(country,x,y) 
     point = Pointed.new(x,y)
     country.the_geom.each do |multipolygon|
       multipolygon.each do |linearring|
         status = self.contains_point?(linearring,point)
         return true if status == true
       end
     end
     return false
  end 

  def self.polygon_extent(country)
     x1 = x2 = y1 = y2 = nil
     country.the_geom.each do |multipolygon|
       multipolygon.each do |linearring|
         linearring.each do |point|
           x1 = point.x if x1 == nil || point.x < x1
           x2 = point.x if x2 == nil || point.x > x2
           y1 = point.y if y1 == nil || point.y < y1
           y2 = point.y if y2 == nil || point.y > y2
         end
       end
     end
     return x1,x2,y1,y2
  end

end

