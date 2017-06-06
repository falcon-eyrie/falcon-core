#ifndef FACTORY_H
#define FACTORY_H

#include <map>
#include <vector>
#include <utility>
//#include <stdexcept>
#include <exception>
#include <iostream>

namespace factory {
    
// exceptions
class UnknownClass : public std::runtime_error {
public:
    UnknownClass( std::string const & error ) : std::runtime_error(error) {}
};
class DuplicateClass : public std::runtime_error {
public:
    DuplicateClass( std::string const & error ) : std::runtime_error(error) {}
};

template <typename AbstractObject, typename ...Args>
using ObjectCreator = AbstractObject* (*) ( Args&& ... );

template <typename AbstractObject,
          typename IdentifierType,
          typename ...Args >
class ObjectFactory {
    typedef ObjectFactory<AbstractObject, IdentifierType, Args...> ThisClass;
    
public:
    
    AbstractObject * create(const IdentifierType & id, Args ...args) {       
        typename ObjectMap::const_iterator i = this->objectmap_.find(id);
        
        if (this->objectmap_.end() != i) {
            return (i->second)(std::forward<Args>(args)...);
        }
        //return (AbstractObject*)NULL;
        throw UnknownClass( "Cannot create object of unregistered class." );
    }
    
    bool hasClass(const IdentifierType & id) {
        return this->objectmap_.find(id) != this->objectmap_.end();
    } 
    
    bool registerClass(const IdentifierType & id, ObjectCreator<AbstractObject, Args...> creator) {
        if (this->objectmap_.find(id) != this->objectmap_.end()) { 
            throw DuplicateClass( "Cannot register the same class twice." );
        }   
        return this->objectmap_.insert(typename ObjectMap::value_type(id, creator)).second;
    }
    
    static ThisClass& instance() {
        static ThisClass factory;
        return factory;
    }
    
    std::vector<IdentifierType> listEntries( ) const {
        std::vector<IdentifierType> entries;
        for (auto imap: objectmap_ ) {
            entries.push_back( imap.first);
        }
        return entries;
    }
    
private:
    typedef std::map<IdentifierType, ObjectCreator<AbstractObject,Args...>> ObjectMap;
    ObjectMap objectmap_;
};

template <typename Base, typename Derived, typename ...Args>
Base * createInstance( Args&& ...args ) {
    return new Derived( std::forward<Args>(args)... ) ;
}


template<class KEY, class BASE, class DERIVED, typename ...Args>
class Registrar {
public:
    Registrar(const KEY & key);
};

template <class KEY, class BASE, class DERIVED, typename ...Args>
Registrar<KEY, BASE, DERIVED, Args...>::Registrar(const KEY & key) {
    ObjectFactory<BASE,KEY,Args...>::instance().registerClass(key, createInstance<BASE, DERIVED, Args...>);
}

#define FACTORYREGISTEROBJECT(BASE,DERIVED,...) \
    namespace { \
        static factory::Registrar<std::string,BASE, DERIVED, ##__VA_ARGS__> _##DERIVED( #DERIVED ); \
    };

} // namespace factory

#endif // FACTORY_H
