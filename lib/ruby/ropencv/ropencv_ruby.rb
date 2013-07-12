module OpenCV
    def self.included(obj)
        obj.class_eval do 
            def cv
                Cv
            end
        end
    end

    class VectorMat
        def self.to_native(obj,context)
            if obj.is_a?(VectorVectorPoint2f)
                t = VectorMat.new
                obj.each do |e|
                    t << cv::Mat.new(e.size,2,cv::CV_32FC1,e.data,cv::Mat::AUTO_STEP)
                end
                t.__obj_ptr__
            elsif obj.is_a?(VectorVectorPoint)
                t = VectorMat.new
                obj.each do |e|
                    t << cv::Mat.new(e.size,2,cv::CV_32SC1,e.data,cv::Mat::AUTO_STEP)
                end
                t.__obj_ptr__
            else
                rbind_to_native(obj,context)
            end
        end
    end

    module Cv
        class String
            def self.to_native(obj,context)
                if obj.is_a? ::String
                    str = obj.to_str
                    OpenCV::Cv::String.new(str,str.length).__obj_ptr__
                else
                    rbind_to_native(obj,context)
                end
            end
            def to_s
                c_str
            end
        end

        class Scalar
            def []=(i,value=nil)
                raise "out of bound #{value}" if value < 0 || value > 3
                val.put_float64(i*8,value)
                value
            end
        end

        class Vec2d
            def [](i)
                raise "Out of bound #{i}" if i < 0 || i > 1 
                val.get_float64(i*8)
            end
            def []=(i,val0)
                raise "Out of bound #{i}" if i < 0 || i > 1 
                val.put_float64(i*8,val0)
            end
        end

        class Vec3d
            def [](i)
                raise "Out of bound #{i}" if i < 0 || i > 2
                val.get_float64(i*8)
            end
            def []=(i,val0)
                raise "Out of bound #{i}" if i < 0 || i > 2
                val.put_float64(i*8,val0)
            end
        end

        class Vec4d
            def [](i)
                raise "Out of bound #{i}" if i < 0 || i > 3
                val.get_float64(i*8)
            end
            def []=(i,val0)
                raise "Out of bound #{i}" if i < 0 || i > 3
                val.put_float64(i*8,val0)
            end
        end

        class Vec4f
            def [](i)
                raise "Out of bound #{i}" if i < 0 || i > 3
                val.get_float32(i*4)
            end
            def []=(i,val0)
                raise "Out of bound #{i}" if i < 0 || i > 3
                val.put_float32(i*4,val0)
            end
        end
        
        class Vec6f
            def [](i)
                raise "Out of bound #{i}" if i < 0 || i > 5
                val.get_float32(i*4)
            end
            def []=(i,val0)
                raise "Out of bound #{i}" if i < 0 || i > 5
                val.put_float32(i*4,val0)
            end
        end

        class Mat
            class << self
                alias :rbind_new :new

                def new(*args)
                    # allow Mat.new([123,23],[2332,32])
                    if !args.find{|a| !a.is_a?(Array)} && args.size() > 1
                        rbind_new(args)
                    else
                        rbind_new(*args)
                    end
                end
            end

            def self.to_native(obj,context)
                if obj.is_a?(VectorPoint2f)
                    cv::Mat.new(obj.size,2,cv::CV_32FC1,obj.data,cv::Mat::AUTO_STEP).__obj_ptr__
                elsif obj.is_a?(VectorPoint3f)
                    cv::Mat.new(obj.size,3,cv::CV_32FC1,obj.data,cv::Mat::AUTO_STEP).__obj_ptr__
                elsif obj.is_a?(Array)
                    h,w,e= if obj.first.is_a? Array
                               [obj.size,obj.first.size,obj.first.first]
                           else
                               [obj.size,1,obj.first]
                           end
                    setter,step,type = if e.is_a? Fixnum
                                           [:put_array_of_uint8,w,CV_8UC1]
                                       elsif e.is_a? Float
                                           [:put_array_of_float64,8*w,CV_64FC1]
                                       else
                                           raise "cannot connvert arrays of #{e.class} to array"
                                       end
                    mat = Mat.new(h,w,type)
                    ptr = mat.data
                    setter = ptr.method(setter)
                    if h == 1 || w == 1
                        setter.call(0,obj)
                    else
                        obj.each_with_index do |row,i|
                            raise "number of row elements must be equal for each row" if row.size != w
                            setter.call(i*step,row)
                        end
                    end
                    mat.__obj_ptr__
                else
                    rbind_to_native(obj,context)
                end
            end

            def -@
                cv::Mat.zeros(rows,cols,type)-self
            end

            def at(i,j=nil)
                i,j = if j == nil
                          if i.is_a?(Cv::Point)
                              [i.y,i.x]
                          elsif rows == 1
                              [0,i]
                          else
                              [i,0]
                          end
                      else
                          [i,j]
                      end
                if i >= rows || i < 0 || j >= cols || j <0
                    raise ArgumentError,"out of bound #{i}/#{j}"
                end
                case type & 7
                when CV_8U
                    data.get_uint8(i*step+j)
                when CV_32F
                    data.get_float32(i*step+j*4)
                when CV_64F
                    data.get_float64(i*step+j*8)
                else
                    raise "cannot connvert #{self.class} to ruby"
                end
            end

            def coerce(other)
                case other
                when Float
                    [other,to_f]
                when Fixnum 
                    [other,to_i]
                else
                    raise TypeError, "#{self.class} can't be coerced into #{other.class}"
                end
            end

            def to_f
                if rows == 1 && cols == 1
                    at(0,0).to_f
                else
                    raise "Matrix #{self} has more than one element"
                end
            end

            def to_i
                if rows == 1 && cols == 1
                    at(0,0).to_i
                else
                    raise "Matrix #{self} has more than one element"
                end
            end

            def set(i,j,val=nil)
                i,j,val = if val == nil
                              if i.is_a?(Cv::Point)
                                  [i.y,i.x,j]
                              elsif rows == 1
                                  [0,i,j]
                              else
                                  [i,0,j]
                              end
                          else
                              [i,j,val]
                          end
                if i >= rows || i < 0 || j >= cols || j <0
                    raise ArgumentError,"out of bound #{i}/#{j}"
                end
                case type & 7
                when CV_8U
                    data.put_uint8(i*step+j,val)
                when CV_32F
                    data.put_float32(i*step+j*4,val)
                when CV_64F
                    data.put_float64(i*step+j*8,val)
                else
                    raise "cannot connvert #{self.class} to ruby"
                end
            end

            def [](i,j=nil)
                at(i,j)
            end

            def []=(i,j,val=nil)
                set(i,j,val)
            end

            def -(val)
                if val.is_a? Float
                    Rbind::cv_mat_operator_minus2( self, val)
                elsif val.is_a? Fixnum
                    Rbind::cv_mat_operator_minus3( self, val)
                else
                    Rbind::cv_mat_operator_minus( self, val)
                end
            end

            def +(val)
                if val.is_a? Float
                    Rbind::cv_mat_operator_plus2( self, val)
                elsif val.is_a? Fixnum
                    Rbind::cv_mat_operator_plus3( self, val)
                else
                    Rbind::cv_mat_operator_plus( self, val)
                end
            end

            def /(val)
                if val.is_a? Float
                    Rbind::cv_mat_operator_div2( self, val)
                elsif val.is_a? Fixnum
                    Rbind::cv_mat_operator_div3( self, val)
                else
                    Rbind::cv_mat_operator_div( self, val)
                end
            end

            def *(val)
                if val.is_a? Float
                    Rbind::cv_mat_operator_mult2( self, val)
                elsif val.is_a? Fixnum
                    Rbind::cv_mat_operator_mult3( self, val)
                else
                    Rbind::cv_mat_operator_mult( self, val)
                end
            end

            def pretty_print(pp)
                format = case type & 7
                         when CV_8U
                             '%3.u'
                         else
                             '%6.3f'
                         end
                str = to_a.map do |r|
                    str = r.map do |e|
                        sprintf(format,e)
                    end.join(" ")
                    "|#{str}|"
                end.join("\n")
                    pp.text str
            end

            def to_a
                h,w,c,s,ptr = [rows,cols,channels,step,data]
                getter = case type & 7
                         when CV_8U
                             ptr.method(:get_array_of_uint8)
                         when CV_32F
                             ptr.method(:get_array_of_float32)
                         when CV_64F
                             ptr.method(:get_array_of_float64)
                         else
                             raise "cannot connvert #{self.class} to array"
                         end
                result = []
                0.upto(h-1) do |i|
                    result << getter.call(s*i,w*c)
                end
                result
            end
        end
    end
end