const coursesData = [
    {
      id: 1,
      title: 'Safeguarding 3',
      location: 'Online',
      date: '28/03/2024 - 28/03/2024',
      link: 'https://faiconnect.ie/mycomet/private/seminars/14066133'
    },
    {
      id: 2,
      title: 'PDP 3',
      location: 'Ballyglass FC, Michael Keaveney Park, Ballyglass, Co. Mayo',
      date: '05/04/2024 - 06/04/2024',
      link: 'https://faiconnect.ie/mycomet/private/seminars/14228434'
    },
    {
      id: 3,
      title: 'PDP 1',
      location: 'Kildimo Community Centre, Coolbeg, Kildimo, County Limerick',
      date: '06/04/2024 - 06/04/2024',
      link: 'https://faiconnect.ie/mycomet/private/seminars/14338495'
    },
    {
      id: 4,
      title: 'PDP 2',
      location: 'Donegal League HQ, Ballyare, Co. Donegal',
      date: '07/04/2024 - 07/04/2024',
      link: 'https://faiconnect.ie/mycomet/private/seminars/13600468'
    },
    {
      id: 5,
      title: '7v7',
      location: 'Brackenstown Rd, Swords Glebe, Swords, Co. Dublin',
      date: '09/04/2024 - 09/04/2024',
      link: 'https://faiconnect.ie/mycomet/private/seminars/12878083'
    },
    {
      id: 6,
      title: 'PDP 3',
      location: 'Ballaghaderreen FC, Toomanagh, Ballaghadereen, Co. Roscommon F45 KP52',
      date: '12/04/2024 - 13/04/2024',
      link: 'https://faiconnect.ie/mycomet/private/seminars/14456716'
    },
    {
      id: 7,
      title: 'PDP 2',
      location: 'Aughrim Rangers AFC',
      date: '13/04/2024 - 13/04/2024',
      link: 'https://faiconnect.ie/mycomet/private/seminars/13941885'
    },
    {
      id: 8,
      title: 'Fundamentals of Goalkeeping',
      location: 'Claremorris AFC, Concannon Park, Claremorris, Co. Mayo F12 X921',
      date: '13/04/2024 - 13/04/2024',
      link: 'https://faiconnect.ie/mycomet/private/seminars/14228886'
    },
    {
      id: 9,
      title: 'PDP 1',
      location: 'Inishowen League HQ, Maginn Park, Buncrana, Co.Donegal',
      date: '13/04/2024 - 13/04/2024',
      link: 'https://faiconnect.ie/mycomet/private/seminars/14455963'
    },
    {
      id: 10,
      title: '9v9',
      location: 'Brackenstown Rd, Swords Glebe, Swords, Co. Dublin',
      date: '16/04/2024 - 16/04/2024',
      link: 'https://faiconnect.ie/mycomet/private/seminars/12878231'
    },
    {
      id: 11,
      title: 'Safeguarding 1',
      location: 'On Line MS Teams',
      date: '16/04/2024 - 16/04/2024',
      link: 'https://faiconnect.ie/mycomet/private/seminars/14780309'
    },
    {
      id: 12,
      title: 'PDP 3',
      location: 'Ferrybank AFC, 1-7 Cherry Cl, Abbeylands, Waterford, Co. Kilkenny',
      date: '19/04/2024 - 21/04/2024',
      link: 'https://faiconnect.ie/mycomet/private/seminars/12788563'
    },
    {
      id: 13,
      title: 'PDP 1',
      location: 'LDSL, Abbeycartron, Longford, N39 R588',
      date: '19/04/2024 - 21/04/2024',
      link: 'https://faiconnect.ie/mycomet/private/seminars/14305949'
    },
    {
      id: 14,
      title: 'PDP 1',
      location: 'Dunmore Town AFC, Barrack Street, Dunmore, Co. Galway, H54 Y624',
      date: '19/04/2024 - 20/04/2024',
      link: 'https://faiconnect.ie/mycomet/private/seminars/14456254'
    },
    {
      id: 15,
      title: 'PDP 1',
      location: 'Portarlington Rugby Club, R32 PR20',
      date: '21/04/2024 - 21/04/2024',
      link: 'https://faiconnect.ie/mycomet/private/seminars/14017379'
    },
    {
      id: 16,
      title: '9v9',
      location: 'Pine Rd, Dublin 4, D04 AE82',
      date: '23/04/2024 - 23/04/2024',
      link: 'https://faiconnect.ie/mycomet/private/seminars/13589038'
    },
    {
      id: 17,
      title: 'Safeguarding 1',
      location: 'On Line MS Teams',
      date: '24/04/2024 - 24/04/2024',
      link: 'https://faiconnect.ie/mycomet/private/seminars/14780424'
    },
    {
      id: 18,
      title: 'PDP 2',
      location: 'Gainstown, Mullingar AFC, Westmeath',
      date: '26/04/2024 - 28/04/2024',
      link: 'https://faiconnect.ie/mycomet/private/seminars/13214577'
    },
    {
      id: 19,
      title: 'PDP 2',
      location: 'Courtown Hibs FC, Ounavarra Park,Boleany, Courtown, Co. Wexford, Y25 PX26',
      date: '26/04/2024 - 28/04/2024',
      link: 'https://faiconnect.ie/mycomet/private/seminars/13798004'
    },
    {
      id: 20,
      title: 'PDP 1',
      location: 'Dundrum FC',
      date: '27/04/2024 - 27/04/2024',
      link: 'https://faiconnect.ie/mycomet/private/seminars/13940671'
    },
    {
      id: 21,
      title: '7v7',
      location: 'Crobally Lower, Tramore, Co. Waterford',
      date: '28/04/2024 - 28/04/2024',
      link: 'https://faiconnect.ie/mycomet/private/seminars/12788625'
    },
    {
      id: 22,
      title: 'PDP 3',
      location: 'Derdimus Park, Derdimus, Co. Kilkenny',
      date: '28/04/2024 - 28/04/2024',
      link: 'https://faiconnect.ie/mycomet/private/seminars/12796635'
    },
    {
      id: 23,
      title: 'PDP 2',
      location: 'Tullamore Town FC, Leah Victoria Park, Axis Business Park, Tullamore, County Offaly, R35 WR61',
      date: '05/05/2024 - 05/05/2024',
      link: 'https://faiconnect.ie/mycomet/private/seminars/14339485'
    },
    {
      id: 24,
      title: 'PDP 1',
      location: 'Rathcoole',
      date: '08/05/2024 - 15/05/2024',
      link: 'https://faiconnect.ie/mycomet/private/seminars/13941257'
    },
    {
      id: 25,
      title: 'PDP 3',
      location: 'Arklow Town FC',
      date: '11/05/2024 - 11/05/2024',
      link: 'https://faiconnect.ie/mycomet/private/seminars/13941983'
    },
    {
      id: 26,
      title: '9v9',
      location: 'Crobally Lower, Tramore, Co. Waterford',
      date: '12/05/2024 - 12/05/2024',
      link: 'https://faiconnect.ie/mycomet/private/seminars/12788714'
    },
    {
      id: 27,
      title: 'PDP 1',
      location: 'Abbeyleix AFC, R32 H7WR',
      date: '13/05/2024 - 20/05/2024',
      link: 'https://faiconnect.ie/mycomet/private/seminars/14017705'
    },
    {
      id: 28,
      title: 'PDP 2',
      location: 'Cabinteely FC',
      date: '17/05/2024 - 18/05/2024',
      link: 'https://faiconnect.ie/mycomet/private/seminars/13941605'
    },
    {
      id: 29,
      title: 'PDP 2',
      location: 'LDSL Abbeycartron Longford N39 R588',
      date: '17/05/2024 - 19/05/2024',
      link: 'https://faiconnect.ie/mycomet/private/seminars/14306044'
    },
    {
      id: 30,
      title: 'Goalkeeping D & C Licence',
      location: 'Mullingar Athletic, Gorteen, Mullingar, Co. Westmeath, N91 D889',
      date: '18/05/2024 - 19/05/2024',
      link: 'https://faiconnect.ie/mycomet/private/seminars/14341932'
    },
    {
      id: 31,
      title: 'PDP 3',
      location: 'Donegal League HQ Ballyare, Co.Donegal',
      date: '19/05/2024 - 19/05/2024',
      link: 'https://faiconnect.ie/mycomet/private/seminars/13601903'
    },
    {
      id: 32,
      title: 'PDP 2',
      location: 'Templeogue',
      date: '19/05/2024 - 19/05/2024',
      link: 'https://faiconnect.ie/mycomet/private/seminars/13941376'
    },
    {
      id: 33,
      title: 'PDP 3',
      location: 'LDSL Abbeycartron Longford N39 R588',
      date: '24/05/2024 - 26/05/2024',
      link: 'https://faiconnect.ie/mycomet/private/seminars/14306164'
    },
    {
      id: 34,
      title: 'PDP 1',
      location: 'Broadford Rovers',
      date: '25/05/2024 - 25/05/2024',
      link: 'https://faiconnect.ie/mycomet/private/seminars/13941156'
    },
    {
      id: 35,
      title: 'PDP 2',
      location: 'Inishowen League HQ, Maginn Park, Buncrana, Co.Donegal',
      date: '28/04/2024 - 28/04/2024',
      link: 'https://faiconnect.ie/mycomet/private/seminars/12796635'
    }
  ];
  
  export default coursesData;
  