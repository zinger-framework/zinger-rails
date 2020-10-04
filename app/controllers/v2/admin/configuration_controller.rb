class V2::Admin::ConfigurationController < V2::AdminController
    def index
        # p = [ 
        #       ["auth","",[],"",[]],
        #       ["auth.x","auth.x",["a","b","c"],"a",["a","b","c"]],
        #       ["auth.y","auth.y",["a","b","c"],"a",["a","b","c"]],
        #       ["auth.z","auth.z",[],"",[]],
        #       ["auth.z.m","auth.z.m",["a","b","c"],"a",["a","b","c"]],
        #       ["auth1","auth1",[],"",[]],
        #       ["auth1.k","auth1.k",["a","b","c"],"a",["a","b","c"]]
        #     ]
        # p = [ 
        #   ["auth","",[],"",[]],
        #   ["auth.x","auth.x",["a","b","c"],"a",["a","b","c"]],
        #   ["auth.y","auth.y",["a","b","c"],"a",["a","b","c"]],
        #   ["auth.z","auth.z",[],"",[]],
        #   ["auth.z.m","auth.z.m",["a","b","c"],"a",["a","b","c"]],
        #   ["auth1.k","auth1.k",["a","b","c"],"a",["a","b","c"]],
        #   ["auth1","auth1",["a","b","c"],"a",["a","b","c"]]
        # ]
        @properties = Property.all
        @properties = @properties.sort_by{|x| x.name}

    end

    def create
         
         #property = Property.new
         # property.name = params[:name]
         # property.text = params[:text]
         # property.default = params[:default]
         
         # property.allowed = ["a","b","c"]
         # property.selected = ["a","b","c"]

         resp = Property.create(name: params['name'],text: params['text'],default: params['default'],
                               allowed: ["a","b","c"],selected: ["a","b","c"]);
         
         
         if resp 
            flash['success'] = 'Property creation is successful'
         else
            flash['warning'] = 'Property creation failed'
         end 

          redirect_to v2_admin_configuration_index_url
    end

    def show
    end

    def update
         print "\n\n\n"
         property = Property.find_by(name: params[:name])
         property.text = params[:text]
         property.default = params[:default]

         if property.save
            puts "update success"
         else
            puts "update failed"
         end
    end

    def destroy
        property = Property.find_by(name: params[:name])
        if property.destroy
            puts  "Delete success"
        else
            puts "Delete failed"
        end
    end
end


