while true
    disp('--------------------')
    disp('Reproducing figures')
    disp('--------------------')
    disp(' [2]  Fig 2: Whack-a-mole effect in the Texas power grid (fig_2_texas_grid_example.m)')
    disp(' [3]  Fig 3: Geographic distribution of the whack-a-mole effect (fig_3_power_grid_whack_a_mole.m)')
    disp(' [4]  Fig 4: Distribution of capacity upgrades(fig_4_county_maps.m)')
    disp(' [4p] Print stats related to Fig 4 (fig_4_print_county_map_stats.m)')
    disp(' [5]  Extended Data Fig 5: Texas power grid - details (ext_data_fig_5_texas_grid_example.m)')
    disp(' [7]  Extended Data Fig 7: The frequency-based strategy results (ext_data_fig_7_frequency_based.m)')
    disp(' [8]  Extended Data Fig 8: Robustness of the upgraded system (ext_data_fig_8_robustness.m)')
    disp(' [9]  Extended Data Fig 9: Failure-based strategy results (ext_data_fig_9_sim_fail_based.m)')
    disp(' [10] Extended Data Fig 10: Overload-based strategy results (ext_data_fig_10_overload_based.m)')
    disp(' [a]  All of the above')
    disp(' [q]  Quit')

    choice = input('Choose the figure to reproduce:', 's');
    addpath('code')
    switch choice
        case '2'
            fig_2_texas_grid_example;
        case '3'
            fig_3_power_grid_whack_a_mole;
        case '4'
            fig_4_county_maps;
        case '4p'
            fig_4_print_county_map_stats;
        case '5'
            ext_data_fig_5_texas_grid_example;
        case '7'
            ext_data_fig_7_frequency_based;
        case '8'
            ext_data_fig_8_robustness;
        case '9'
            ext_data_fig_9_sim_fail_based;
        case '10'
            ext_data_fig_10_overload_based;
        case 'a'
            fig_2_texas_grid_example;
            fig_3_power_grid_whack_a_mole;
            fig_4_county_maps;
            ext_data_fig_5_texas_grid_example;
            ext_data_fig_7_frequency_based;
            ext_data_fig_8_robustness;
            ext_data_fig_9_sim_fail_based;
            ext_data_fig_10_overload_based;
            return
        otherwise
            return
    end
end