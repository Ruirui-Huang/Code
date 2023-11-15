/**
 * @brief:  根据水流断面和水面分割图，选取有效的线段，用于后续选点操作
 * @param:  water_line          [IN]  输入水流断面
 *          mask                [IN]  输入水面分割结果
 *          valid_line          [OUT] 输出选取好的线段
 *          valid_pixel_counts  [OUT] 输出有效线段上的有效像素点总和
 *          img_width           [IN]  原图的宽
 *          img_height          [IN]  原图的高
 * @return: 返回线段的数量
 **/
ivs_sint32_t SubfuncWaterVelocityDeep::GetValidLine(
    dhivs_line_t      water_line, 
    dhpipe_os_mask_t *mask,
    dhivs_line_t     *valid_line, 
    ivs_sint32_t     *valid_pixel_counts,
    ivs_sint32_t      img_width, 
    ivs_sint32_t      img_height,
    ivs_sint32_t     &flag_direction_x, 
    ivs_uint8_t      *mask_result,
    ivs_real32_t     &k, 
    ivs_real32_t     &b)
{
    ivs_sint32_t flag_point   = 0;
    ivs_sint32_t index        = 0;
    ivs_sint32_t pixel_counts = 0;
    ivs_sint32_t start_point  = 0;
    ivs_sint32_t end_point    = 0;

    // 计算直线表达式
    ivs_real32_t delta_x = (ivs_real32_t)(water_line.end.x - water_line.start.x);
    ivs_real32_t delta_y = (ivs_real32_t)(water_line.end.y - water_line.start.y);
    if (delta_x == 0 && delta_y == 0)
    {
        ALG_LOG_ERROR("[%s] Invalid Line\n", __FUNCTION__);
        return DHIVS_ERR_INVALID_PARAM;
    }
    // 根据斜率判断标定线取点方向，斜率绝对值<= 1，取点方向为x轴方向，反之取点方向为y轴方向
    flag_direction_x = abs(delta_y) <= abs(delta_x) ? 1 : 0;

    k = flag_direction_x ? delta_y / delta_x : delta_x / delta_y;
    b = flag_direction_x ? ((water_line.start.y * water_line.end.x - water_line.end.y * water_line.start.x) / delta_x) : ((water_line.start.x * water_line.end.y - water_line.end.x * water_line.start.y) / delta_y);
    start_point = flag_direction_x ? (delta_x >= 0 ? water_line.start.x : water_line.end.x) : (delta_y >= 0 ? water_line.start.y : water_line.end.y);
    end_point   = flag_direction_x ? (delta_x >= 0 ? water_line.end.x : water_line.start.x) : (delta_y >= 0 ? water_line.end.y : water_line.start.y);

    //   计算每个点之间的间隔
    for (ivs_sint32_t id = start_point; id < end_point; id++)
    {
        ivs_sint32_t x      = flag_direction_x ? id : k * id + b;
        ivs_sint32_t y      = flag_direction_x ? k * id + b : id;
        ivs_sint32_t mask_x = (ivs_sint32_t)(1.0 * x / img_width * mask->width);
        ivs_sint32_t mask_y = (ivs_sint32_t)(1.0 * y / img_height * mask->height);
        if (mask_result[mask_x + mask->width * mask_y] == 1)
        {
            if (flag_point == 0)
            {
                flag_point = id;
            }
        }
        else
        {
            // 起始点与终止点之间的像素至少要超过50个，存入有效线段中，便于后续选点
            if (flag_point != 0 && (id - flag_point) > 50)
            {
                valid_line[index].start.x = flag_direction_x ? flag_point : k * flag_point + b;
                valid_line[index].start.y = flag_direction_x ? k * flag_point + b : flag_point;  // 与边缘相隔25个像素
                valid_line[index].end.x = flag_direction_x ? id : k * id + b;
                valid_line[index].end.y = flag_direction_x ? k * id + b : id;  // 与边缘相隔25个像素
                pixel_counts = pixel_counts + (flag_direction_x ? valid_line[index].end.x - valid_line[index].start.x : valid_line[index].end.y - valid_line[index].start.y);
                index++;
                // 开始标志置0
                flag_point = 0;
            }
        }
    }
    // 处理边界，遍历到最后仍为河面的场景
    if (flag_point != 0 && (end_point - flag_point) > 50)
    {
        valid_line[index].start.x = flag_direction_x ? flag_point : k * flag_point + b;
        valid_line[index].start.y = flag_direction_x ? k * flag_point + b : flag_point;  // 与边缘相隔25个像素
        valid_line[index].end.x   = flag_direction_x ? end_point - 25 : k * (end_point - 25) + b;
        valid_line[index].end.y   = flag_direction_x ? k * (end_point - 25) + b : end_point - 25;  // 与边缘相隔25个像素
        pixel_counts              = pixel_counts + (flag_direction_x ? valid_line[index].end.x - valid_line[index].start.x : valid_line[index].end.y - valid_line[index].start.y);
        index++;
    }
    *valid_pixel_counts = pixel_counts;
    return index;
}

ivs_sint32_t SubfuncWaterVelocityDeep::SelectObservePoints(
    dhpipe_os_mask_t *mask, 
    ivs_sint32_t      observe_pts_num,
    ivs_sint32_t      optical_pts_num,
    ivs_sint32_t      img_width,
    ivs_sint32_t      img_height)
{
    ALG_LOG_INFO("[%s] SelectObservePoints start!\n", __FUNCTION__);
    dhivs_line_t valid_line[20]         = {0};
    ivs_sint32_t observe_index          = 0;
    ivs_sint32_t opticalflow_index      = 0;
    ivs_sint32_t valid_line_counts      = 0;
    ivs_sint32_t valid_pixel_counts     = 0;
    ivs_sint32_t flag_line_direction_x  = 0;
    ivs_sint32_t point_num              = 0;
    ivs_sint32_t delta                  = 0;
    ivs_real32_t k                      = 0.0;
    ivs_real32_t b                      = 0.0;
    ivs_sint32_t win_size               = (ivs_sint32_t)(sqrt(optical_pts_num) / 2);
    ivs_sint32_t remain_observe_pts_num = observe_pts_num;  //  剩余点的数量
    dhivs_line_t water_line             = {0};
    ivs_uint8_t* mask_result            = (ivs_uint8_t*)mask->data;
    memcpy(&this->cache_line_, &this->water_line_, sizeof(dhivs_line_t));
    memcpy(&this->cache_roi_, &this->water_roi_, sizeof(dhivs_polygon_t));

    ///< 重新对mask类别进行映射
    ///< 背景0 水面1 天空2 船只3 竹筏4 绿植3 蓝藻6 生活垃圾7 行人8
    ///< 前景：1  背景: 0、2、3、4、5、6、7、8
    ivs_sint32_t ret = MaskTypeMap(mask, mask_result);

    // 将水流断面映射回原图坐标系
    water_line.start.x = ivs_sint32_t(this->water_line_.start.x * img_width / COR_1024);
    water_line.start.y = ivs_sint32_t(this->water_line_.start.y * img_height / COR_1024);
    water_line.end.x   = ivs_sint32_t(this->water_line_.end.x * img_width / COR_1024);
    water_line.end.y   = ivs_sint32_t(this->water_line_.end.y * img_height / COR_1024);

    // 1. 获取所有有效线段
    valid_line_counts = GetValidLine(water_line, mask, valid_line, &valid_pixel_counts, img_width, img_height, flag_line_direction_x, mask_result, k, b);
    if (valid_pixel_counts != 0)
    {
        // 2. 遍历所有有效线段，开始选点
        for (ivs_sint32_t i = 0; i < valid_line_counts; i++)
        {
            // 2.1 确定本线段所需点数，按比例设置每个线段所需的点数
            point_num = flag_line_direction_x ? ivs_sint32_t(1.0 * abs(valid_line[i].end.x - valid_line[i].start.x) / valid_pixel_counts * observe_pts_num) : ivs_sint32_t(1.0 * abs(valid_line[i].end.y - valid_line[i].start.y) / valid_pixel_counts * observe_pts_num);
            delta     = flag_line_direction_x ? (valid_line[i].end.x - valid_line[i].start.x) / point_num : (valid_line[i].end.y - valid_line[i].start.y) / point_num;

            if (point_num < 1)
            {
                continue;
            }
            //  剩余的点全部分配给最后一条线段
            if (i == valid_line_counts - 1)
            {
                point_num = remain_observe_pts_num;
            }
            remain_observe_pts_num -= point_num;
            // 2.2 开始选点
            if (point_num >= MAX_VELOCITY_POINT_NUM)
            {
                ALG_LOG_WARNING("[%s] Select observe_pts failed\n", __FUNCTION__);
                return DHIVS_OK;
            }
            if (point_num * 2 * win_size * 2 * win_size >= MAX_OPTICALFLOW_POINT_NUM)
            {
                ALG_LOG_WARNING("[%s] Select init_pts failed\n", __FUNCTION__);
                return DHIVS_OK;
            }

            // 2.2 开始选点
            for (ivs_sint32_t j = 0; j < point_num; j++)
            {
                // 确定观测点坐标,在配置线段上选点
                if (flag_line_direction_x)
                {
                    this->observe_pts_[observe_index].x = valid_line[i].start.x + j * delta;
                    this->observe_pts_[observe_index].y = k * this->observe_pts_[observe_index].x + b;
                }
                else
                {
                    this->observe_pts_[observe_index].y = valid_line[i].start.y + j * delta;
                    this->observe_pts_[observe_index].x = k * this->observe_pts_[observe_index].y + b;
                }

                // 以观测点为中心，选择win_size窗口内的点用于计算光流
                for (ivs_sint32_t x = this->observe_pts_[observe_index].x - win_size;
                     x <= this->observe_pts_[observe_index].x + win_size; x++)
                {
                    for (ivs_sint32_t y = this->observe_pts_[observe_index].y - win_size;
                         y <= this->observe_pts_[observe_index].y + win_size; y++)
                    {
                        this->init_pts_[opticalflow_index].x = x;
                        this->init_pts_[opticalflow_index].y = y;
                        opticalflow_index++;
                    }
                }
                observe_index++;
            }
        }
    }

    ALG_LOG_INFO("[%s] SelectObservePoints end!\n", __FUNCTION__);
    return DHIVS_OK;
}