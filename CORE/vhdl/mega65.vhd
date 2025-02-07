----------------------------------------------------------------------------------
-- MiSTer2MEGA65 Framework
--
-- MEGA65 main file that contains the whole machine
--
-- MiSTer2MEGA65 done by sy2002 and MJoergen in 2022 and licensed under GPL v3
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.globals.all;
use work.types_pkg.all;
use work.video_modes_pkg.all;

library xpm;
use xpm.vcomponents.all;

entity MEGA65_Core is
generic (
    G_BOARD : string
);
port (
   
   -- Share clock and reset with the framework
   main_clk_o              : out std_logic;              -- Burnin'Rubber's 12 MHz main clock
   main_rst_o              : out std_logic;              -- Burnin'Rubber's reset, synchronized
   
   video_clk_o             : out std_logic;              -- video clock 48 MHz
   video_rst_o             : out std_logic;              -- video reset, synchronized

   --------------------------------------------------------------------------------------------------------
   -- QNICE Clock Domain
   --------------------------------------------------------------------------------------------------------

   -- Get QNICE clock from the framework: for the vdrives as well as for RAMs and ROMs
   qnice_clk_i             : in  std_logic;
   qnice_rst_i             : in  std_logic;

   -- Video and audio mode control
   qnice_dvi_o             : out std_logic;              -- 0=HDMI (with sound), 1=DVI (no sound)
   qnice_video_mode_o      : out video_mode_type;        -- Defined in video_modes_pkg.vhd
   qnice_scandoubler_o     : out std_logic;              -- 0 = no scandoubler, 1 = scandoubler
   qnice_audio_mute_o      : out std_logic;
   qnice_audio_filter_o    : out std_logic;
   qnice_zoom_crop_o       : out std_logic;
   qnice_ascal_mode_o      : out std_logic_vector(1 downto 0);
   qnice_ascal_polyphase_o : out std_logic;
   qnice_ascal_triplebuf_o : out std_logic;
   qnice_retro15kHz_o      : out std_logic;              -- 0 = normal frequency, 1 = retro 15 kHz frequency
   qnice_csync_o           : out std_logic;              -- 0 = normal HS/VS, 1 = Composite Sync  
   qnice_osm_cfg_scaling_o : out std_logic_vector(8 downto 0);

   -- Flip joystick ports
   qnice_flip_joyports_o   : out std_logic;

   -- On-Screen-Menu selections
   qnice_osm_control_i     : in  std_logic_vector(255 downto 0);

   -- QNICE general purpose register
   qnice_gp_reg_i          : in  std_logic_vector(255 downto 0);

   -- Core-specific devices
   qnice_dev_id_i          : in  std_logic_vector(15 downto 0);
   qnice_dev_addr_i        : in  std_logic_vector(27 downto 0);
   qnice_dev_data_i        : in  std_logic_vector(15 downto 0);
   qnice_dev_data_o        : out std_logic_vector(15 downto 0);
   qnice_dev_ce_i          : in  std_logic;
   qnice_dev_we_i          : in  std_logic;
   qnice_dev_wait_o        : out std_logic;

   --------------------------------------------------------------------------------------------------------
   -- Core Clock Domain
   --------------------------------------------------------------------------------------------------------

   -- M2M's reset manager provides 2 signals:
   --    m2m:   Reset the whole machine: Core and Framework
   --    core:  Only reset the core
   clk_i                   : in  std_logic;
   main_reset_m2m_i        : in  std_logic;
   main_reset_core_i       : in  std_logic;

   main_pause_core_i       : in  std_logic;

   -- Video output
   video_ce_o              : out std_logic;
   video_ce_ovl_o          : out std_logic;
   video_red_o             : out std_logic_vector(7 downto 0);
   video_green_o           : out std_logic_vector(7 downto 0);
   video_blue_o            : out std_logic_vector(7 downto 0);
   video_vs_o              : out std_logic;
   video_hs_o              : out std_logic;
   video_hblank_o          : out std_logic;
   video_vblank_o          : out std_logic;
  
   -- Audio output (Signed PCM)
   main_audio_left_o       : out signed(15 downto 0);
   main_audio_right_o      : out signed(15 downto 0);

   -- M2M Keyboard interface (incl. drive led)
   main_kb_key_num_i       : in  integer range 0 to 79;  -- cycles through all MEGA65 keys
   main_kb_key_pressed_n_i : in  std_logic;              -- low active: debounced feedback: is kb_key_num_i pressed right now?
   main_power_led_o        : out std_logic;
   main_power_led_col_o    : out std_logic_vector(23 downto 0);    
   main_drive_led_o        : out std_logic;
   main_drive_led_col_o    : out std_logic_vector(23 downto 0);

    -- Joysticks and paddles input
   main_joy_1_up_n_i       : in  std_logic;
   main_joy_1_down_n_i     : in  std_logic;
   main_joy_1_left_n_i     : in  std_logic;
   main_joy_1_right_n_i    : in  std_logic;
   main_joy_1_fire_n_i     : in  std_logic;
   main_joy_1_up_n_o       : out std_logic;
   main_joy_1_down_n_o     : out std_logic;
   main_joy_1_left_n_o     : out std_logic;
   main_joy_1_right_n_o    : out std_logic;
   main_joy_1_fire_n_o     : out std_logic;
   main_joy_2_up_n_i       : in  std_logic;
   main_joy_2_down_n_i     : in  std_logic;
   main_joy_2_left_n_i     : in  std_logic;
   main_joy_2_right_n_i    : in  std_logic;
   main_joy_2_fire_n_i     : in  std_logic;
   main_joy_2_up_n_o       : out std_logic;
   main_joy_2_down_n_o     : out std_logic;
   main_joy_2_left_n_o     : out std_logic;
   main_joy_2_right_n_o    : out std_logic;
   main_joy_2_fire_n_o     : out std_logic;
   
   main_pot1_x_i           : in  std_logic_vector(7 downto 0);
   main_pot1_y_i           : in  std_logic_vector(7 downto 0);
   main_pot2_x_i           : in  std_logic_vector(7 downto 0);
   main_pot2_y_i           : in  std_logic_vector(7 downto 0);
   main_rtc_i              : in  std_logic_vector(64 downto 0);
   
    -- C64 Expansion Port (aka Cartridge Port)
   cart_en_o               : out std_logic;  -- Enable port, active high
   cart_phi2_o             : out std_logic;
   cart_dotclock_o         : out std_logic;
   cart_dma_i              : in  std_logic;
   cart_reset_oe_o         : out std_logic;
   cart_reset_i            : in  std_logic;
   cart_reset_o            : out std_logic;
   cart_game_oe_o          : out std_logic;
   cart_game_i             : in  std_logic;
   cart_game_o             : out std_logic;
   cart_exrom_oe_o         : out std_logic;
   cart_exrom_i            : in  std_logic;
   cart_exrom_o            : out std_logic;
   cart_nmi_oe_o           : out std_logic;
   cart_nmi_i              : in  std_logic;
   cart_nmi_o              : out std_logic;
   cart_irq_oe_o           : out std_logic;
   cart_irq_i              : in  std_logic;
   cart_irq_o              : out std_logic;
   cart_roml_oe_o          : out std_logic;
   cart_roml_i             : in  std_logic;
   cart_roml_o             : out std_logic;
   cart_romh_oe_o          : out std_logic;
   cart_romh_i             : in  std_logic;
   cart_romh_o             : out std_logic;
   cart_ctrl_oe_o          : out std_logic; -- 0 : tristate (i.e. input), 1 : output
   cart_ba_i               : in  std_logic;
   cart_rw_i               : in  std_logic;
   cart_io1_i              : in  std_logic;
   cart_io2_i              : in  std_logic;
   cart_ba_o               : out std_logic;
   cart_rw_o               : out std_logic;
   cart_io1_o              : out std_logic;
   cart_io2_o              : out std_logic;
   cart_addr_oe_o          : out std_logic; -- 0 : tristate (i.e. input), 1 : output
   cart_a_i                : in  unsigned(15 downto 0);
   cart_a_o                : out unsigned(15 downto 0);
   cart_data_oe_o          : out std_logic; -- 0 : tristate (i.e. input), 1 : output
   cart_d_i                : in  unsigned( 7 downto 0);
   cart_d_o                : out unsigned( 7 downto 0);
   
   -- CBM-488/IEC serial port
   iec_reset_n_o           : out std_logic;
   iec_atn_n_o             : out std_logic;
   iec_clk_en_o            : out std_logic;
   iec_clk_n_i             : in  std_logic;
   iec_clk_n_o             : out std_logic;
   iec_data_en_o           : out std_logic;
   iec_data_n_i            : in  std_logic;
   iec_data_n_o            : out std_logic;
   iec_srq_en_o            : out std_logic;
   iec_srq_n_i             : in  std_logic;
   iec_srq_n_o             : out std_logic;

   -- On-Screen-Menu selections
   main_osm_control_i      : in  std_logic_vector(255 downto 0);

   -- QNICE general purpose register converted to main clock domain
   main_qnice_gp_reg_i     : in  std_logic_vector(255 downto 0);

   --------------------------------------------------------------------------------------------------------
   -- Provide HyperRAM to core (in HyperRAM clock domain)
   --------------------------------------------------------------------------------------------------------

   hr_clk_i                : in  std_logic;
   hr_rst_i                : in  std_logic;
   hr_core_write_o         : out std_logic := '0';
   hr_core_read_o          : out std_logic := '0';
   hr_core_address_o       : out std_logic_vector(31 downto 0) := (others => '0');
   hr_core_writedata_o     : out std_logic_vector(15 downto 0) := (others => '0');
   hr_core_byteenable_o    : out std_logic_vector( 1 downto 0) := (others => '0');
   hr_core_burstcount_o    : out std_logic_vector( 7 downto 0) := (others => '0');
   hr_core_readdata_i      : in  std_logic_vector(15 downto 0);
   hr_core_readdatavalid_i : in  std_logic;
   hr_core_waitrequest_i   : in  std_logic;
   hr_high_i               : in  std_logic;  -- Core is too fast
   hr_low_i                : in  std_logic   -- Core is too slow
);
end entity MEGA65_Core;

architecture synthesis of MEGA65_Core is

---------------------------------------------------------------------------------------------
-- Clocks and active high reset signals for each clock domain
---------------------------------------------------------------------------------------------

signal main_clk            : std_logic;               -- Core main clock
signal main_rst            : std_logic;

signal video_clk           : std_logic;               
signal video_rst           : std_logic;

---------------------------------------------------------------------------------------------
-- main_clk (MiSTer core's clock)
---------------------------------------------------------------------------------------------

-- Unprocessed video output from the Burnin'Rubber core
signal main_video_red      : std_logic_vector(2 downto 0);   
signal main_video_green    : std_logic_vector(2 downto 0);
signal main_video_blue     : std_logic_vector(1 downto 0);
signal main_video_vs       : std_logic;
signal main_video_hs       : std_logic;
signal main_video_hblank   : std_logic;
signal main_video_vblank   : std_logic;

---------------------------------------------------------------------------------------------
-- qnice_clk
---------------------------------------------------------------------------------------------

constant C_MENU_OSMPAUSE      : natural := 2;  
constant C_MENU_OSMDIM        : natural := 3;
constant C_FLIP_JOYS          : natural := 4;
constant C_MENU_ROT90         : natural := 8;
constant C_MENU_FLIP          : natural := 9;
constant C_MENU_CRT_EMULATION : natural := 10;
constant C_MENU_HDMI_16_9_50  : natural := 14;
constant C_MENU_HDMI_16_9_60  : natural := 15;
constant C_MENU_HDMI_4_3_50   : natural := 16;
constant C_MENU_HDMI_5_4_50   : natural := 17;

constant C_MENU_VGA_STD       : natural := 23;
constant C_MENU_VGA_15KHZHSVS : natural := 27;
constant C_MENU_VGA_15KHZCS   : natural := 28;

constant C_MENU_DECO          : natural := 34;

-- DECO DIPs
-- Dipswitch A
constant C_MENU_DECO_DSWA_0 : natural := 37;
constant C_MENU_DECO_DSWA_1 : natural := 38;
constant C_MENU_DECO_DSWA_2 : natural := 39;
constant C_MENU_DECO_DSWA_3 : natural := 40;
constant C_MENU_DECO_DSWA_4 : natural := 41;
constant C_MENU_DECO_DSWA_5 : natural := 42;
constant C_MENU_DECO_DSWA_6 : natural := 43;
constant C_MENU_DECO_DSWA_7 : natural := 44;

-- Dipswitch B
constant C_MENU_DECO_DSWB_0 : natural := 46;
constant C_MENU_DECO_DSWB_1 : natural := 47;
constant C_MENU_DECO_DSWB_2 : natural := 48;
constant C_MENU_DECO_DSWB_3 : natural := 49;
constant C_MENU_DECO_DSWB_4 : natural := 50;
constant C_MENU_DECO_DSWB_5 : natural := 51;
constant C_MENU_DECO_DSWB_6 : natural := 52;
constant C_MENU_DECO_DSWB_7 : natural := 53;


-- Burnin'Rubber specific video processing
signal div          : std_logic_vector(2 downto 0);
signal dim_video    : std_logic;
signal dsw_a_i      : std_logic_vector(7 downto 0);
signal dsw_b_i      : std_logic_vector(7 downto 0);

signal old_clk      : std_logic;
signal ce_vid       : std_logic;
signal ce_pix       : std_logic;

signal video_ce     : std_logic;
signal video_red    : std_logic_vector(7 downto 0);
signal video_green  : std_logic_vector(7 downto 0);
signal video_blue   : std_logic_vector(7 downto 0);
signal video_vs     : std_logic;
signal video_hs     : std_logic;
signal video_vblank : std_logic;
signal video_hblank : std_logic;
signal video_de     : std_logic;

signal video_rot_red    : std_logic_vector(7 downto 0);
signal video_rot_green  : std_logic_vector(7 downto 0);
signal video_rot_blue   : std_logic_vector(7 downto 0);
signal video_rot_vs     : std_logic;
signal video_rot_hs     : std_logic;
signal video_rot_vblank : std_logic;
signal video_rot_hblank : std_logic;
signal video_rot_de     : std_logic;

signal video_rot90_flag : std_logic;

-- Output from screen_rotate
signal ddram_addr       : std_logic_vector(28 downto 0);
signal ddram_data       : std_logic_vector(63 downto 0);
signal ddram_be         : std_logic_vector( 7 downto 0);
signal ddram_we         : std_logic;

-- ROM devices for Burnin'Rubber
signal qnice_dn_addr    : std_logic_vector(15 downto 0);
signal qnice_dn_data    : std_logic_vector(7 downto 0);
signal qnice_dn_wr      : std_logic;

constant C_320_288_50 : video_modes_t := (
   CLK_KHZ     => 6000,       -- 6 MHz
   CLK_SEL     => "111",
   CEA_CTA_VIC => 0,
   ASPECT      => "01",       -- aspect ratio: 01=4:3, 10=16:9: "01" for SVGA
   PIXEL_REP   => '0',        -- no pixel repetition
   H_PIXELS    => 320,        -- horizontal display width in pixels
   V_PIXELS    => 240,        -- vertical display width in rows
   H_PULSE     => 28,         -- horizontal sync pulse width in pixels
   H_BP        => 28,         -- horizontal back porch width in pixels
   H_FP        => 8,          -- horizontal front porch width in pixels
   V_PULSE     => 2,          -- vertical sync pulse width in rows
   V_BP        => 22,         -- vertical back porch width in rows
   V_FP        => 1,          -- vertical front porch width in rows
   H_POL       => '1',        -- horizontal sync pulse polarity (1 = positive, 0 = negative)
   V_POL       => '1'         -- vertical sync pulse polarity (1 = positive, 0 = negative)
);

begin

   -- Configure the LEDs:
   -- Power led on and green, drive led always off
   main_power_led_o       <= '1';
   main_power_led_col_o   <= x"00FF00";
   main_drive_led_o       <= '0';
   main_drive_led_col_o   <= x"00FF00"; 

   -- MMCME2_ADV clock generators:
   clk_gen : entity work.clk
      port map (
         sys_clk_i         => clk_i,             -- expects 100 MHz
         sys_rstn_i        => main_reset_m2m_i,  -- Asynchronous, asserted low
         
         main_clk_o        => main_clk,        -- Burnin'Rubber's 12 MHz main clock
         main_rst_o        => main_rst,        -- Burnin'Rubber's reset, synchronized
         
         video_clk_o       => video_clk,       -- video clock 48 MHz
         video_rst_o       => video_rst        -- video reset, synchronized
      
      ); -- clk_gen
      
      
   i_cdc_qnice2video : xpm_cdc_array_single
      generic map (
         WIDTH => 1
      )
      port map (
         src_clk           => qnice_clk_i,
         src_in(0)         => qnice_osm_control_i(C_MENU_ROT90),
         dest_clk          => video_clk,
         dest_out(0)       => video_rot90_flag
      ); -- i_cdc_qnice2video


   main_clk_o   <= main_clk;
   main_rst_o   <= main_rst;
   video_clk_o  <= video_clk;
   video_rst_o  <= video_rst;
   
   dsw_a_i <= main_osm_control_i(C_MENU_DECO_DSWA_7) &
              main_osm_control_i(C_MENU_DECO_DSWA_6) &
              main_osm_control_i(C_MENU_DECO_DSWA_5) &
              main_osm_control_i(C_MENU_DECO_DSWA_4) &
              main_osm_control_i(C_MENU_DECO_DSWA_3) &
              main_osm_control_i(C_MENU_DECO_DSWA_2) &
              main_osm_control_i(C_MENU_DECO_DSWA_1) &
              main_osm_control_i(C_MENU_DECO_DSWA_0);
   
  dsw_b_i <=  main_osm_control_i(C_MENU_DECO_DSWB_7) &
              main_osm_control_i(C_MENU_DECO_DSWB_6) &
              main_osm_control_i(C_MENU_DECO_DSWB_5) &
              main_osm_control_i(C_MENU_DECO_DSWB_4) &
              main_osm_control_i(C_MENU_DECO_DSWB_3) &
              main_osm_control_i(C_MENU_DECO_DSWB_2) &
              main_osm_control_i(C_MENU_DECO_DSWB_1) &
              main_osm_control_i(C_MENU_DECO_DSWB_0);
   
            
   ---------------------------------------------------------------------------------------------
   -- main_clk (MiSTer core's clock)
   ---------------------------------------------------------------------------------------------

   -- main.vhd contains the actual MiSTer core
   i_main : entity work.main
      generic map (
         G_VDNUM              => C_VDNUM
         
      )
      port map (
         clk_main_i           => main_clk,
         reset_soft_i         => main_reset_core_i,
         reset_hard_i         => main_reset_m2m_i,
         pause_i              => main_pause_core_i and main_osm_control_i(C_MENU_OSMPAUSE),
         dim_video_o          => dim_video,
         clk_main_speed_i     => CORE_CLK_SPEED,
         
         -- Video output
         -- This is PAL 720x576 @ 50 Hz (pixel clock 27 MHz), but synchronized to main_clk (54 MHz).
         video_clk_o          => video_clk_o,
         video_ce_o           => ce_vid,
         video_ce_ovl_o       => open,
         video_red_o          => main_video_red,
         video_green_o        => main_video_green,
         video_blue_o         => main_video_blue,
         video_vs_o           => main_video_vs,
         video_hs_o           => main_video_hs,
         video_hblank_o       => main_video_hblank,
         video_vblank_o       => main_video_vblank,
         
         -- Audio output (PCM format, signed values)
         audio_left_o         => main_audio_left_o,
         audio_right_o        => main_audio_right_o,

         -- M2M Keyboard interface
         kb_key_num_i         => main_kb_key_num_i,
         kb_key_pressed_n_i   => main_kb_key_pressed_n_i,

         -- MEGA65 joysticks and paddles/mouse/potentiometers
         joy_1_up_n_i         => main_joy_1_up_n_i ,
         joy_1_down_n_i       => main_joy_1_down_n_i,
         joy_1_left_n_i       => main_joy_1_left_n_i,
         joy_1_right_n_i      => main_joy_1_right_n_i,
         joy_1_fire_n_i       => main_joy_1_fire_n_i,
         joy_2_up_n_i         => main_joy_2_up_n_i,
         joy_2_down_n_i       => main_joy_2_down_n_i,
         joy_2_left_n_i       => main_joy_2_left_n_i,
         joy_2_right_n_i      => main_joy_2_right_n_i,
         joy_2_fire_n_i       => main_joy_2_fire_n_i,
         pot1_x_i             => main_pot1_x_i,
         pot1_y_i             => main_pot1_y_i,
         pot2_x_i             => main_pot2_x_i,
         pot2_y_i             => main_pot2_y_i,

         dn_clk_i             => qnice_clk_i,
         dn_addr_i            => qnice_dn_addr,
         dn_data_i            => qnice_dn_data,
         dn_wr_i              => qnice_dn_wr,

         osm_control_i        => main_osm_control_i,
         dsw_a_i              => dsw_a_i,
         dsw_b_i              => dsw_b_i
      ); -- i_main

    process (video_clk) -- 48 MHz
    begin
        if rising_edge(video_clk) then
        
            old_clk <= ce_vid;
            ce_pix  <= old_clk and (not ce_vid);
            
            video_ce_ovl_o <= '0';
            div <= std_logic_vector(unsigned(div) + 1);
            if div(0) = '1' then
               video_ce_ovl_o <= '1'; -- 24 MHz
            end if;

            if dim_video = '1' then
                video_red   <= "0" & main_video_red   & main_video_red   & main_video_red(2 downto 2);
                video_green <= "0" & main_video_green & main_video_green & main_video_green(2 downto 2);
                video_blue  <= "0" & main_video_blue  & main_video_blue  & main_video_blue & main_video_blue(1 downto 1);  
            else
                video_red   <= main_video_red   & main_video_red   & main_video_red(2 downto 1);
                video_green <= main_video_green & main_video_green & main_video_green(2 downto 1);
                video_blue  <= main_video_blue  & main_video_blue  & main_video_blue & main_video_blue;
            end if;

            video_hs     <= not main_video_hs;
            video_vs     <= not main_video_vs;
            video_hblank <= main_video_hblank;
            video_vblank <= main_video_vblank;
            video_de     <= not (main_video_hblank or main_video_vblank);
        end if;
    end process;
    
    p_select_video_signals : process(video_rot90_flag)
    begin
        if video_rot90_flag then
           video_red_o      <= video_rot_red;
           video_green_o    <= video_rot_green;
           video_blue_o     <= video_rot_blue;
           video_vs_o       <= video_rot_vs;
           video_hs_o       <= video_rot_hs;
           video_hblank_o   <= video_rot_hblank;
           video_vblank_o   <= video_rot_vblank;
           video_ce_o       <= ce_pix;
       else
           video_red_o      <= video_red;
           video_green_o    <= video_green;
           video_blue_o     <= video_blue;
           video_vs_o       <= video_vs;
           video_hs_o       <= video_hs;
           video_hblank_o   <= video_hblank;
           video_vblank_o   <= video_vblank;
           video_ce_o       <= ce_pix;
       end if;
    end process;

    i_screen_rotate : entity work.screen_rotate
       port map (
          --inputs
          CLK_VIDEO      => video_clk,
          CE_PIXEL       => ce_pix,
          VGA_R          => video_red,
          VGA_G          => video_green,
          VGA_B          => video_blue,
          VGA_HS         => video_hs,
          VGA_VS         => video_vs,
          VGA_DE         => video_de,
          rotate_ccw     => '0',
          no_rotate      => '0',
          flip           => '0',
          FB_VBL         => '0',
          FB_LL          => '0',
          -- output to screen_buffer
          video_rotated  => open,
          DDRAM_CLK      => video_clk,
          DDRAM_BUSY     => '0',
          DDRAM_BURSTCNT => open,
          DDRAM_ADDR     => ddram_addr,
          DDRAM_DIN      => ddram_data,
          DDRAM_BE       => ddram_be,
          DDRAM_WE       => ddram_we,
          DDRAM_RD       => open
      ); -- i_screen_rotate

   -- Here G_ADDR_WIDTH is determined by the total number of visible pixels,
   -- since each word in memory stores one pixel.
   -- Here we have 288*224 = 64512, i.e. 16 bits of address is enough.
   i_frame_buffer : entity work.frame_buffer
      generic map (
         G_ADDR_WIDTH => 16,
         G_H_LEFT     => 40,
         G_H_RIGHT    => 240+40,
         G_VIDEO_MODE => C_320_288_50
      )
      
      port map (
         ddram_clk_i      => video_clk,
         ddram_addr_i     => ddram_addr(14 downto 0) & ddram_be(7),
         ddram_din_i      => ddram_data(31 downto 0),
         ddram_we_i       => ddram_we,
         video_clk_i      => video_clk,
         video_ce_i       => ce_pix,
         video_red_o      => video_rot_red,
         video_green_o    => video_rot_green,
         video_blue_o     => video_rot_blue,
         video_vs_o       => video_rot_vs,
         video_hs_o       => video_rot_hs,
         video_hblank_o   => video_rot_hblank,
         video_vblank_o   => video_rot_vblank
      ); -- i_frame_buffer

   ---------------------------------------------------------------------------------------------
   -- Audio and video settings (QNICE clock domain)
   ---------------------------------------------------------------------------------------------

   -- Due to a discussion on the MEGA65 discord (https://discord.com/channels/719326990221574164/794775503818588200/1039457688020586507)
   -- we decided to choose a naming convention for the PAL modes that might be more intuitive for the end users than it is
   -- for the programmers: "4:3" means "meant to be run on a 4:3 monitor", "5:4 on a 5:4 monitor".
   -- The technical reality is though, that in our "5:4" mode we are actually doing a 4/3 aspect ratio adjustment
   -- while in the 4:3 mode we are outputting a 5:4 image. This is kind of odd, but it seemed that our 4/3 aspect ratio
   -- adjusted image looks best on a 5:4 monitor and the other way round.
   -- Not sure if this will stay forever or if we will come up with a better naming convention.
   qnice_video_mode_o <= C_VIDEO_HDMI_5_4_50   when qnice_osm_control_i(C_MENU_HDMI_5_4_50)    = '1' else
                         C_VIDEO_HDMI_4_3_50   when qnice_osm_control_i(C_MENU_HDMI_4_3_50)    = '1' else
                         C_VIDEO_HDMI_16_9_60  when qnice_osm_control_i(C_MENU_HDMI_16_9_60)   = '1' else
                         C_VIDEO_HDMI_16_9_50;
   -- qnice_retro15kHz_o: '1', if the output from the core (post-scandoubler) in the retro 15 kHz analog RGB mode.
   --             Hint: Scandoubler off does not automatically mean retro 15 kHz on.
   qnice_scandoubler_o        <= (not qnice_osm_control_i(C_MENU_VGA_15KHZHSVS)) and
                                 (not qnice_osm_control_i(C_MENU_VGA_15KHZCS));   
   qnice_retro15kHz_o <= qnice_osm_control_i(C_MENU_VGA_15KHZHSVS) or qnice_osm_control_i(C_MENU_VGA_15KHZCS);
   qnice_csync_o      <= qnice_osm_control_i(C_MENU_VGA_15KHZCS);

   -- Zoom out the OSM
   qnice_osm_cfg_scaling_o    <= (others => '1');

   -- Use On-Screen-Menu selections to configure several audio and video settings
   -- Video and audio mode control
   qnice_dvi_o                <= '0';                                         -- 0=HDMI (with sound), 1=DVI (no sound)
   qnice_audio_mute_o         <= '0';                                         -- audio is not muted
   qnice_audio_filter_o       <= '1';                                         -- 0 = raw audio, 1 = use filters from globals.vhd

   -- ascal filters that are applied while processing the input
   -- 00 : Nearest Neighbour
   -- 01 : Bilinear
   -- 10 : Sharp Bilinear
   -- 11 : Bicubic
   qnice_ascal_mode_o         <= "00";

   -- If polyphase is '1' then the ascal filter mode is ignored and polyphase filters are used instead
   -- @TODO: Right now, the filters are hardcoded in the M2M framework, we need to make them changeable inside m2m-rom.asm
   qnice_ascal_polyphase_o    <= qnice_osm_control_i(C_MENU_CRT_EMULATION);

   -- ascal triple-buffering
   -- @TODO: Right now, the M2M framework only supports OFF, so do not touch until the framework is upgraded
   qnice_ascal_triplebuf_o    <= '0';

   -- Flip joystick ports (i.e. the joystick in port 2 is used as joystick 1 and vice versa)
   qnice_flip_joyports_o      <= qnice_osm_control_i(C_FLIP_JOYS);

   ---------------------------------------------------------------------------------------------
   -- Core specific device handling (QNICE clock domain)
   ---------------------------------------------------------------------------------------------

   core_specific_devices : process(all)
   begin
      -- make sure that this is x"EEEE" by default and avoid a register here by having this default value
      qnice_dev_data_o <= x"EEEE";
      qnice_dev_wait_o <= '0';

      -- Default values
      qnice_dn_wr      <= '0';
      qnice_dn_addr    <= (others => '0');
      qnice_dn_data    <= (others => '0');

      case qnice_dev_id_i is


--romp_cs  <= '1' when dn_addr(15 downto 14) = "00"   else '0'; - main cpu
--rom_cs   <= '1' when dn_addr(15 downto 12) = "1100" else '0'; - audio cpu
--roms1_cs <= '1' when dn_addr(15 downto 13) = "010"  else '0'; - gfx 1
--roms2_cs <= '1' when dn_addr(15 downto 13) = "011"  else '0'; - gfx 1
--roms3_cs <= '1' when dn_addr(15 downto 13) = "100"  else '0'; - gfx 1
--romb1_cs <= '1' when dn_addr(15 downto 12) = "1010" else '0'; - gfx 2
--romb2_cs <= '1' when dn_addr(15 downto 12) = "1011" else '0'; - gfx 2


         when C_DEV_BNJ_CPU_ROM1 =>
              qnice_dn_wr   <= qnice_dev_ce_i and qnice_dev_we_i;
              qnice_dn_addr <= "000" & qnice_dev_addr_i(12 downto 0);    
              qnice_dn_data <= qnice_dev_data_i(7 downto 0);
         
         when C_DEV_BNJ_CPU_ROM2 =>
              qnice_dn_wr   <= qnice_dev_ce_i and qnice_dev_we_i;
              qnice_dn_addr <= "001" & qnice_dev_addr_i(12 downto 0);  
              qnice_dn_data <= qnice_dev_data_i(7 downto 0);

         when C_DEV_BNJ_CPU_ROM3 =>
              qnice_dn_wr   <= qnice_dev_ce_i and qnice_dev_we_i;
              qnice_dn_addr <= "1100" & qnice_dev_addr_i(11 downto 0); 
              qnice_dn_data <= qnice_dev_data_i(7 downto 0);

         when C_DEV_BNJ_GFX1_1 =>
              qnice_dn_wr   <= qnice_dev_ce_i and qnice_dev_we_i;
              qnice_dn_addr <= "010" & qnice_dev_addr_i(12 downto 0);   
              qnice_dn_data <= qnice_dev_data_i(7 downto 0);

         when C_DEV_BNJ_GFX1_2 =>
              qnice_dn_wr   <= qnice_dev_ce_i and qnice_dev_we_i;
              qnice_dn_addr <= "011" & qnice_dev_addr_i(12 downto 0);
              qnice_dn_data <= qnice_dev_data_i(7 downto 0);

         when C_DEV_BNJ_GFX1_3 =>
              qnice_dn_wr   <= qnice_dev_ce_i and qnice_dev_we_i;
              qnice_dn_addr <= "100" & qnice_dev_addr_i(12 downto 0); 
              qnice_dn_data <= qnice_dev_data_i(7 downto 0);

         when C_DEV_BNJ_GFX2_1 =>
              qnice_dn_wr   <= qnice_dev_ce_i and qnice_dev_we_i;
              qnice_dn_addr <= "1010" & qnice_dev_addr_i(11 downto 0); 
              qnice_dn_data <= qnice_dev_data_i(7 downto 0);
              
         when C_DEV_BNJ_GFX2_2 =>
              qnice_dn_wr   <= qnice_dev_ce_i and qnice_dev_we_i;
              qnice_dn_addr <= "1011" & qnice_dev_addr_i(11 downto 0); 
              qnice_dn_data <= qnice_dev_data_i(7 downto 0);

         when others => null;
      end case;

      if qnice_rst_i = '1' then
         qnice_dn_wr <= '0';
      end if;
   end process core_specific_devices;

   ---------------------------------------------------------------------------------------------
   -- Dual Clocks
   ---------------------------------------------------------------------------------------------

   -- Put your dual-clock devices such as RAMs and ROMs here
   --
   -- Use the M2M framework's official RAM/ROM: dualport_2clk_ram
   -- and make sure that the you configure the port that works with QNICE as a falling edge
   -- by setting G_FALLING_A or G_FALLING_B (depending on which port you use) to true.


end architecture synthesis;

