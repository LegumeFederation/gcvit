import React from 'react';

/**
 * Key for displayed datasets.
 */

export default class key extends React.Component {
    state = {
	    visible : false,
    }

    render () {
	    var {visible} = this.state;
	    var {datasets} = this.props;
	    console.log(datasets);
	    var keys = datasets.map((data,i) => {
		var keyItem = [];
		if(data.genotype && data.color) {
			if (i === 0) {
				keyItem.push(<div className={'pure-u-1-4 l-box'} style={{fontWeight:'bold'}}> Reference </div>);
			} else if (i === 1) {
				keyItem.push(<div className={'pure-u-1-4 l-box'} style={{fontWeigth:'bold'}}> Variants </div>);
			} 

			//keyItem.push(<div className={'pure-u-1-4 l-box'} style={{background:data.color}}> {data.genotype.label} </div>);
			keyItem.push(<div className={'pure-u-1-4 l-box'}> <div className={'key-color'} style={{background: data.color}}>{`    `}</div> {data.genotype.label} </div>);
			
			if (i === 0) {
				keyItem.push(<div className={'pure-u-1-2 l-box'}> </div>);
			}
		}
		
		return keyItem;
	    } );
	    
        return(
	<div>
   	  <div className={'pure-u-1-1 l-box fake-button'}>
            <div className={'pure-g l-box'} onClick={()=>{this.setState({visible : !visible});}}>
              <div className={'pure-u-1-12 l-box'} > <div className={visible ? 'arrow-down':'arrow-down rotate'}/> </div>
              <div className={'pure-u-5-6 l-box'}> Key </div>
              <div className={'pure-u-1-12 l-box'} > <div className={visible ? 'arrow-down':'arrow-down rotate'}/> </div>
	    </div>
	  </div>
	  <div className={'key-box'} style={{display: visible ? "block" : "none"}}>
	    <div className={'pure-g l-box'}>
		{keys}
            </div>
          </div>
	</div>
        );
    }
}
