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
         resp = Property.create(name: params['name'],text: params['text'],default: params['default'],
            allowed: ["a","b","c"],selected: ["a","b","c"]);
         
         
         if resp 
            flash['success'] = 'Property creation is successful'
         else
            flash['danger'] = 'Property creation failed'
         end 

          redirect_to v2_admin_configuration_index_url
    end

    def update
         property = Property.find_by_id(params['id'])

         if property.blank?
             flash['danger'] = 'Unable to find property'
             redirect_to v2_admin_configuration_index_url
         end

         property.update_attributes(name: params['name'], text: params['text'],default: params['default'],selected: ['a','b','c'],allowed: ['a','b','c'])

         if property.errors.any?
            flash['danger'] = 'Property updation failed'
         else
            flash['success'] = 'Property updation is successful'
         end
         redirect_to v2_admin_configuration_index_url
    end

    def destroy
        property = Property.find_by_id(params['id'])
        if property.blank?
             flash['danger'] = 'Unable to find property'
             redirect_to v2_admin_configuration_index_url
        end

        if property.destroy
            flash['success'] = 'Property deletion is successful'
        else
            flash['danger'] = 'Property deletion failed'
        end
        redirect_to v2_admin_configuration_index_url

    end
end


